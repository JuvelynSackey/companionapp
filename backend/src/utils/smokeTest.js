/**
 * End-to-end smoke test against a running server.
 *
 *   node src/utils/smokeTest.js
 *
 * Walks the whole student journey from the proposal's system-testing example
 * (login -> dashboard -> schedule -> grades -> events) plus the admin paths,
 * and checks that authorisation is actually enforced rather than assumed.
 * Also covers admin provisioning of lecturer accounts, role permissions,
 * self-registration never granting a privileged role, lecturer event
 * create/delete (with ownership rules), and the quiz lifecycle
 * (create -> fetch without answer key -> attempt -> delete).
 *
 * Needs the seeded demo accounts (`npm run db:setup`). Safe to re-run: quizzes
 * and events are deleted at the end; each run leaves two accounts behind
 * (smoke-lecturer-*, smoke-register-*), since there is no delete-user endpoint.
 */
import { readFile } from 'node:fs/promises';

const BASE = process.env.API_BASE ?? 'http://localhost:4000/api';

let passed = 0;
let failed = 0;

function check(name, condition, detail = '') {
  if (condition) {
    passed++;
    console.log(`  PASS  ${name}`);
  } else {
    failed++;
    console.log(`  FAIL  ${name}${detail ? ` — ${detail}` : ''}`);
  }
}

async function call(method, path, { token, body } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  let data = null;
  try {
    data = await res.json();
  } catch {
    /* 204 responses have no body */
  }

  return { status: res.status, data };
}

async function run() {
  console.log(`\nSmoke test against ${BASE}\n`);

  console.log('Health');
  const health = await call('GET', '/health');
  check('health reports ok', health.data?.status === 'ok', JSON.stringify(health.data));

  console.log('\nModule 1 — authentication');
  const login = await call('POST', '/auth/login', {
    body: { email: 'student@ug.edu.gh', password: 'student123' },
  });
  check('student can log in', login.status === 200 && !!login.data?.token);
  const studentToken = login.data?.token;

  const adminLogin = await call('POST', '/auth/login', {
    body: { email: 'admin@ug.edu.gh', password: 'admin123' },
  });
  check('admin can log in', adminLogin.status === 200 && !!adminLogin.data?.token);
  const adminToken = adminLogin.data?.token;

  const badLogin = await call('POST', '/auth/login', {
    body: { email: 'student@ug.edu.gh', password: 'wrong-password' },
  });
  check('wrong password rejected', badLogin.status === 401);

  const noToken = await call('GET', '/dashboard');
  check('protected route rejects missing token', noToken.status === 401);

  const badToken = await call('GET', '/dashboard', { token: 'not-a-real-token' });
  check('protected route rejects forged token', badToken.status === 401);

  const me = await call('GET', '/auth/me', { token: studentToken });
  check('me returns the student', me.data?.user?.email === 'student@ug.edu.gh');
  check('me never leaks the password hash', me.data?.user?.password_hash === undefined);

  const weakPassword = await call('POST', '/auth/register', {
    body: { fullName: 'Test User', email: 'weak@ug.edu.gh', password: 'abc' },
  });
  check('short password rejected', weakPassword.status === 400);

  const duplicate = await call('POST', '/auth/register', {
    body: { fullName: 'Impostor', email: 'student@ug.edu.gh', password: 'password123' },
  });
  check('duplicate email rejected', duplicate.status === 409);

  console.log('\nModule 2 — dashboard & schedule');
  const dash = await call('GET', '/dashboard', { token: studentToken });
  check('dashboard returns stats', typeof dash.data?.stats?.classesToday === 'number');
  check('dashboard returns announcements', Array.isArray(dash.data?.announcements));
  check('dashboard returns upcoming events', Array.isArray(dash.data?.upcomingEvents));

  const week = await call('GET', '/schedule', { token: studentToken });
  check('week has 6 seeded classes', week.data?.schedule?.length === 6,
    `got ${week.data?.schedule?.length}`);

  const friday = await call('GET', '/schedule?day=5', { token: studentToken });
  check('Friday has 4 classes', friday.data?.schedule?.length === 4,
    `got ${friday.data?.schedule?.length}`);
  check('Friday classes are time-ordered',
    friday.data?.schedule?.[0]?.startTime === '10:00');
  check('schedule includes lecturer name',
    friday.data?.schedule?.[0]?.lecturer === 'Prof. A. Mensah');

  const badDay = await call('GET', '/schedule?day=99', { token: studentToken });
  check('invalid day rejected', badDay.status === 400);

  console.log('\nModule 4 — grades & GPA');
  const grades = await call('GET', '/grades', { token: studentToken });
  check('4 grades returned', grades.data?.grades?.length === 4);
  check('GPA is 3.64 (credit-weighted)', grades.data?.summary?.gpa === 3.64,
    `got ${grades.data?.summary?.gpa}`);
  check('average score is 82.5', grades.data?.summary?.averageScore === 82.5,
    `got ${grades.data?.summary?.averageScore}`);

  const maths = grades.data?.grades?.find((g) => g.courseTitle === 'Mathematics');
  check('score 85 maps to letter A', maths?.letterGrade === 'A', `got ${maths?.letterGrade}`);

  const studentPostsGrade = await call('POST', '/grades', {
    token: studentToken,
    body: { userId: 1, courseId: 1, score: 100 },
  });
  check('student cannot post grades', studentPostsGrade.status === 403);

  console.log('\nModule 4b — University of Ghana grading scale (docs/grading-scale-ug.json)');
  // The same fixture the Flutter parity test reads, so server and app are held to one table.
  const ug = JSON.parse(await readFile(new URL('../../../docs/grading-scale-ug.json', import.meta.url), 'utf8'));
  const bandFor = (score) => ug.scale.find((band) => score >= band.min);
  const round2 = (n) => Number(n.toFixed(2));
  const gradeRunId = Date.now();

  const catalog = await call('GET', '/courses', { token: adminToken });
  const courseByCode = new Map((catalog.data?.courses ?? []).map((c) => [c.courseCode, c]));

  // A fresh student per scenario: GPA is cumulative, so the seeded student's
  // 3.64 (checked above) must not be disturbed. Grades cannot be deleted, so
  // each run leaves these smoke-grades-* accounts behind; `npm run db:setup` resets them.
  const newStudent = async (label) => {
    const res = await call('POST', '/auth/register', {
      body: {
        fullName: `Smoke Grades ${label}`,
        email: `smoke-grades-${label}-${gradeRunId}@ug.edu.gh`,
        password: 'smokepass123',
      },
    });
    return { userId: res.data?.user?.userId, token: res.data?.token };
  };
  const postGrade = (userId, courseCode, score, semester) =>
    call('POST', '/grades', {
      token: adminToken,
      body: { userId, courseId: courseByCode.get(courseCode)?.courseId, score, semester },
    });

  // Every boundary mark, one semester each, all on the same 3-credit course.
  const boundary = await newStudent('boundary');
  check('boundary-test student created', typeof boundary.userId === 'number');
  for (const [i, score] of ug.boundaryScores.entries()) {
    const expected = bandFor(score);
    const res = await postGrade(boundary.userId, 'DCIT 201', score, `Smoke boundary ${i}`);
    check(`mark ${score} is graded ${expected.letter}`,
      res.status === 201 && res.data?.letterGrade === expected.letter,
      `status ${res.status}, got ${res.data?.letterGrade}`);
  }

  const boundaryList = await call('GET', '/grades', { token: boundary.token });
  const boundaryRows = boundaryList.data?.grades ?? [];
  check('all boundary marks are listed', boundaryRows.length === ug.boundaryScores.length,
    `got ${boundaryRows.length}`);
  check('only a grade of F is a fail (passed flag)',
    boundaryRows.every((g) => g.passed === (g.letterGrade !== 'F')));
  check('a mark of 55 passes (it failed under the old proposal scale)',
    boundaryRows.find((g) => g.score === 55)?.passed === true);
  // Same course and credits for every row, so the credit weighting cancels out.
  const expectedBoundaryGpa = round2(
    ug.boundaryScores.reduce((sum, score) => sum + bandFor(score).points, 0) / ug.boundaryScores.length);
  check(`GPA over every boundary mark is ${expectedBoundaryGpa}`,
    boundaryList.data?.summary?.gpa === expectedBoundaryGpa, `got ${boundaryList.data?.summary?.gpa}`);

  // Hand-computed transcripts across courses with different credit hours.
  for (const transcript of ug.transcripts.filter((t) => t.viaApi)) {
    const student = await newStudent(transcript.name.split(' ')[0]);
    let creditsMatch = true;
    for (const row of transcript.rows) {
      creditsMatch &&= courseByCode.get(row.course)?.creditHours === row.credits;
      await postGrade(student.userId, row.course, row.score, 'Smoke transcript');
    }
    check(`transcript "${transcript.name}": course credit hours match the fixture`, creditsMatch);
    const res = await call('GET', '/grades', { token: student.token });
    check(`transcript "${transcript.name}" gives GPA ${transcript.expectedGpa}`,
      res.data?.summary?.gpa === transcript.expectedGpa, `got ${res.data?.summary?.gpa}`);
  }

  console.log('\nModule 3 — announcements');
  const anns = await call('GET', '/announcements', { token: studentToken });
  check('announcements returned', anns.data?.announcements?.length >= 2);
  check('newest announcement first',
    anns.data?.announcements?.[0]?.datePosted >= anns.data?.announcements?.[1]?.datePosted);

  const studentPostsAnn = await call('POST', '/announcements', {
    token: studentToken,
    body: { title: 'Fake notice', message: 'Should be blocked', category: 'emergency' },
  });
  check('student cannot post announcements', studentPostsAnn.status === 403);

  const adminPostsAnn = await call('POST', '/announcements', {
    token: adminToken,
    body: { title: 'Smoke test notice', message: 'Posted by the smoke test.' },
  });
  check('admin can post announcements', adminPostsAnn.status === 201);

  if (adminPostsAnn.data?.announcementId) {
    const del = await call('DELETE', `/announcements/${adminPostsAnn.data.announcementId}`, {
      token: adminToken,
    });
    check('admin can delete announcements', del.status === 204);
  }

  console.log('\nModule 5 — events & clubs');
  const events = await call('GET', '/events', { token: studentToken });
  check('events returned', events.data?.events?.length >= 2);
  const firstEvent = events.data?.events?.[0];
  check('event carries organising club', !!firstEvent?.clubName);

  const rsvp = await call('POST', `/events/${firstEvent?.eventId}/register`, {
    token: studentToken,
  });
  check('student can RSVP', rsvp.status === 201);

  const rsvpAgain = await call('POST', `/events/${firstEvent?.eventId}/register`, {
    token: studentToken,
  });
  check('double RSVP is harmless', rsvpAgain.status === 201 && rsvpAgain.data?.alreadyRegistered === true);

  const afterRsvp = await call('GET', '/events', { token: studentToken });
  const rsvpedEvent = afterRsvp.data?.events?.find((e) => e.eventId === firstEvent?.eventId);
  check('event now shows isRegistered', rsvpedEvent?.isRegistered === true);
  check('attendee count incremented', rsvpedEvent?.attendeeCount === 1,
    `got ${rsvpedEvent?.attendeeCount}`);

  const cancel = await call('DELETE', `/events/${firstEvent?.eventId}/register`, {
    token: studentToken,
  });
  check('student can cancel RSVP', cancel.status === 204);

  const clubs = await call('GET', '/clubs', { token: studentToken });
  check('3 clubs seeded', clubs.data?.clubs?.length === 3);

  const join = await call('POST', `/clubs/${clubs.data?.clubs?.[0]?.clubId}/join`, {
    token: studentToken,
  });
  check('student can join a club', join.status === 201);

  const leave = await call('DELETE', `/clubs/${clubs.data?.clubs?.[0]?.clubId}/join`, {
    token: studentToken,
  });
  check('student can leave a club', leave.status === 204);

  console.log('\nModule 6 — campus map');
  const locs = await call('GET', '/locations', { token: studentToken });
  check('6 locations seeded', locs.data?.locations?.length === 6,
    `got ${locs.data?.locations?.length}`);
  check('coordinates are numbers', typeof locs.data?.locations?.[0]?.latitude === 'number');

  const libraries = await call('GET', '/locations?category=library', { token: studentToken });
  check('category filter works', libraries.data?.locations?.length === 1);

  const search = await call('GET', '/locations?search=balme', { token: studentToken });
  check('search is case-insensitive', search.data?.locations?.[0]?.name === 'Balme Library');

  const badCategory = await call('GET', '/locations?category=nonsense', { token: studentToken });
  check('invalid category rejected', badCategory.status === 400);

  // Quizzes and events created below are tracked so they are removed even if
  // a check throws part-way. Deleting a quiz cascades to its questions and
  // attempts; deleting an event cascades to its RSVPs. Accounts are NOT
  // cleaned up (there is no delete-user endpoint), so each run leaves a
  // smoke-lecturer-* and a smoke-register-* row behind; `npm run db:setup`
  // resets them.
  const createdQuizIds = [];
  const createdEventIds = [];
  try {
    console.log('\nAdmin — provisioning elevated accounts');
    const runId = Date.now();
    const lecturerAccount = {
      fullName: 'Smoke Test Lecturer',
      email: `smoke-lecturer-${runId}@ug.edu.gh`,
      password: 'smokepass123',
      role: 'lecturer',
    };

    const noTokenProvision = await call('POST', '/admin/provision-user', { body: lecturerAccount });
    check('provisioning rejects a missing token', noTokenProvision.status === 401);

    const studentProvision = await call('POST', '/admin/provision-user', {
      token: studentToken,
      body: lecturerAccount,
    });
    check('student cannot provision accounts', studentProvision.status === 403);

    const badRole = await call('POST', '/admin/provision-user', {
      token: adminToken,
      body: { ...lecturerAccount, role: 'student' },
    });
    check('provisioning rejects role "student"', badRole.status === 400);

    const weakProvision = await call('POST', '/admin/provision-user', {
      token: adminToken,
      body: { ...lecturerAccount, password: 'abc' },
    });
    check('provisioning rejects a short password', weakProvision.status === 400);

    const provisioned = await call('POST', '/admin/provision-user', {
      token: adminToken,
      body: lecturerAccount,
    });
    check('admin can provision a lecturer', provisioned.status === 201);
    check('provisioned user has the lecturer role', provisioned.data?.user?.role === 'lecturer',
      `got ${provisioned.data?.user?.role}`);
    check('provisioning never leaks the password hash',
      !JSON.stringify(provisioned.data ?? {}).includes('password'));

    const duplicateProvision = await call('POST', '/admin/provision-user', {
      token: adminToken,
      body: lecturerAccount,
    });
    check('provisioning a duplicate email is rejected', duplicateProvision.status === 409);

    console.log('\nRoles & permissions');
    const lecturerLogin = await call('POST', '/auth/login', {
      body: { email: lecturerAccount.email, password: lecturerAccount.password },
    });
    check('provisioned lecturer can log in', lecturerLogin.status === 200 && !!lecturerLogin.data?.token);
    const lecturerToken = lecturerLogin.data?.token;

    check('login reports the lecturer role', lecturerLogin.data?.user?.role === 'lecturer');
    check('lecturer holds quizzes:create',
      lecturerLogin.data?.user?.permissions?.includes('quizzes:create') === true);
    check('lecturer holds events:create',
      lecturerLogin.data?.user?.permissions?.includes('events:create') === true);
    check('lecturer does not hold admin permissions',
      !lecturerLogin.data?.user?.permissions?.includes('announcements:write'));
    check('student does not hold quizzes:create',
      login.data?.user?.permissions?.includes('quizzes:create') === false);

    const lecturerMe = await call('GET', '/auth/me', { token: lecturerToken });
    check('me returns the lecturer', lecturerMe.data?.user?.email === lecturerAccount.email);

    // Privilege escalation: a client-supplied role must never be honoured.
    const escalation = await call('POST', '/auth/register', {
      body: {
        fullName: 'Smoke Escalation',
        email: `smoke-register-${runId}@ug.edu.gh`,
        password: 'smokepass123',
        role: 'admin',
      },
    });
    check('self-registration succeeds', escalation.status === 201 && !!escalation.data?.token);
    check('registration ignores a client-supplied role (response)', escalation.data?.user?.role === 'student',
      `got ${escalation.data?.user?.role}`);
    const escalationMe = await call('GET', '/auth/me', { token: escalation.data?.token });
    check('stored role is student (read back from the database)', escalationMe.data?.user?.role === 'student',
      `got ${escalationMe.data?.user?.role}`);
    check('registered account has no elevated permissions',
      !escalationMe.data?.user?.permissions?.includes('announcements:write') &&
      !escalationMe.data?.user?.permissions?.includes('quizzes:create'));
    const escalatedPost = await call('POST', '/announcements', {
      token: escalation.data?.token,
      body: { title: 'Escalated notice', message: 'Should be blocked' },
    });
    check('registered account cannot use admin routes', escalatedPost.status === 403,
      `got ${escalatedPost.status}`);

    const lecturerProvision = await call('POST', '/admin/provision-user', {
      token: lecturerToken,
      body: { ...lecturerAccount, email: `smoke-other-${runId}@ug.edu.gh` },
    });
    check('lecturer cannot provision accounts', lecturerProvision.status === 403);

    const lecturerAnn = await call('POST', '/announcements', {
      token: lecturerToken,
      body: { title: 'Lecturer notice', message: 'Should be blocked' },
    });
    check('lecturer cannot post announcements', lecturerAnn.status === 403);

    const lecturerGrade = await call('POST', '/grades', {
      token: lecturerToken,
      body: { userId: 1, courseId: 1, score: 100 },
    });
    check('lecturer cannot post grades', lecturerGrade.status === 403);

    console.log('\nEvents — lecturer create & delete');
    const eventBody = (title) => ({
      title,
      description: 'Created by the smoke test.',
      eventDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
      location: 'Smoke Test Hall',
    });
    const findEvent = async (id) => {
      const list = await call('GET', '/events', { token: studentToken });
      return list.data?.events?.find((e) => e.eventId === id);
    };

    const studentEvent = await call('POST', '/events', {
      token: studentToken,
      body: eventBody(`Student event ${runId}`),
    });
    if (studentEvent.data?.eventId) createdEventIds.push(studentEvent.data.eventId);
    check('student cannot create events (403)', studentEvent.status === 403, `got ${studentEvent.status}`);

    const invalidEvent = await call('POST', '/events', { token: lecturerToken, body: {} });
    check('invalid event body rejected (400)', invalidEvent.status === 400);

    const eventA = await call('POST', '/events', {
      token: lecturerToken,
      body: eventBody(`Smoke event A ${runId}`),
    });
    check('lecturer can create an event', eventA.status === 201 && typeof eventA.data?.eventId === 'number');
    const eventAId = eventA.data?.eventId;
    if (eventAId) createdEventIds.push(eventAId);

    const eventB = await call('POST', '/events', {
      token: lecturerToken,
      body: eventBody(`Smoke event B ${runId}`),
    });
    const eventBId = eventB.data?.eventId;
    if (eventBId) createdEventIds.push(eventBId);

    check("student sees the lecturer's event", (await findEvent(eventAId))?.title === `Smoke event A ${runId}`);

    const studentDeleteEvent = await call('DELETE', `/events/${eventAId}`, { token: studentToken });
    check('student cannot delete events', studentDeleteEvent.status === 403);

    // "Someone else's" event is one the admin creates here, not a seeded one,
    // so a broken ownership check can never delete real data.
    const adminEvent = await call('POST', '/events', {
      token: adminToken,
      body: eventBody(`Smoke admin event ${runId}`),
    });
    const adminEventId = adminEvent.data?.eventId;
    if (adminEventId) createdEventIds.push(adminEventId);
    check('admin can create an event', adminEvent.status === 201);

    const lecturerDeleteOther = await call('DELETE', `/events/${adminEventId}`, { token: lecturerToken });
    check('lecturer cannot delete an event they did not create', lecturerDeleteOther.status === 403,
      `got ${lecturerDeleteOther.status}`);
    check("the admin's event is still there", !!(await findEvent(adminEventId)));

    const badEventId = await call('DELETE', '/events/not-a-number', { token: lecturerToken });
    check('non-numeric event id returns 404', badEventId.status === 404, `got ${badEventId.status}`);

    const missingEvent = await call('DELETE', '/events/999999', { token: lecturerToken });
    check('deleting a missing event returns 404', missingEvent.status === 404);

    // An RSVP must not block deletion (it cascades).
    const rsvpA = await call('POST', `/events/${eventAId}/register`, { token: studentToken });
    check("student can RSVP to the lecturer's event", rsvpA.status === 201);

    const ownDelete = await call('DELETE', `/events/${eventAId}`, { token: lecturerToken });
    check('lecturer can delete their own event (with RSVPs)', ownDelete.status === 204, `got ${ownDelete.status}`);
    if (ownDelete.status === 204) createdEventIds.splice(createdEventIds.indexOf(eventAId), 1);
    check('deleted event no longer listed', (await findEvent(eventAId)) === undefined);

    const ownDeleteAgain = await call('DELETE', `/events/${eventAId}`, { token: lecturerToken });
    check('deleting the same event again returns 404', ownDeleteAgain.status === 404);

    const adminDeleteEvent = await call('DELETE', `/events/${eventBId}`, { token: adminToken });
    check("admin can delete any lecturer's event", adminDeleteEvent.status === 204, `got ${adminDeleteEvent.status}`);
    if (adminDeleteEvent.status === 204) createdEventIds.splice(createdEventIds.indexOf(eventBId), 1);

    const adminDeleteOwn = await call('DELETE', `/events/${adminEventId}`, { token: adminToken });
    check('admin can delete their own event', adminDeleteOwn.status === 204, `got ${adminDeleteOwn.status}`);
    if (adminDeleteOwn.status === 204) createdEventIds.splice(createdEventIds.indexOf(adminEventId), 1);

    console.log('\nModule 7 — quizzes');
    const courses = await call('GET', '/courses', { token: studentToken });
    const courseId = courses.data?.courses?.[0]?.courseId;
    check('course catalog available for quizzes', typeof courseId === 'number');

    const mcq = (questionText, options, correctOption) => ({
      questionType: 'multiple_choice', questionText, options, correctOption,
    });
    const quizBody = {
      courseId,
      title: `Smoke test quiz ${runId}`,
      questions: [
        mcq('Which planet is closest to the Sun?', ['Venus', 'Mercury', 'Mars'], 1),
        mcq('What is 2 + 2?', ['4', '5', '6'], 0),
        { questionType: 'open_ended', questionText: 'Name one renewable energy source.', modelAnswer: 'Solar' },
      ],
    };

    const studentQuiz = await call('POST', '/quizzes', { token: studentToken, body: quizBody });
    if (studentQuiz.data?.quizId) createdQuizIds.push(studentQuiz.data.quizId);
    check('student cannot create quizzes', studentQuiz.status === 403, `got ${studentQuiz.status}`);

    const badMcq = await call('POST', '/quizzes', {
      token: lecturerToken,
      body: { ...quizBody, questions: [mcq('Out-of-range answer?', ['A', 'B'], 5)] },
    });
    check('multiple-choice answer index out of range rejected', badMcq.status === 400);

    const badOpen = await call('POST', '/quizzes', {
      token: lecturerToken,
      body: { ...quizBody, questions: [{ questionType: 'open_ended', questionText: 'No model answer?' }] },
    });
    check('open-ended question without a model answer rejected', badOpen.status === 400);

    const unknownCourse = await call('POST', '/quizzes', {
      token: lecturerToken,
      body: { ...quizBody, courseId: 999999 },
    });
    check('quiz for an unknown course rejected', unknownCourse.status === 400);

    const created = await call('POST', '/quizzes', { token: lecturerToken, body: quizBody });
    check('lecturer can create a quiz', created.status === 201 && typeof created.data?.quizId === 'number');
    const quizId = created.data?.quizId;
    if (quizId) createdQuizIds.push(quizId);

    const quizList = await call('GET', `/quizzes?courseId=${courseId}`, { token: studentToken });
    const listed = quizList.data?.quizzes?.find((q) => q.quizId === quizId);
    check('student sees the quiz in the list', !!listed);
    check('list reports the question count', listed?.questionCount === 3, `got ${listed?.questionCount}`);

    const quiz = await call('GET', `/quizzes/${quizId}`, { token: studentToken });
    check('student can fetch the quiz', quiz.status === 200 && quiz.data?.title === quizBody.title);
    check('quiz has all 3 questions', quiz.data?.questions?.length === 3);
    check('questions keep their authored order',
      quiz.data?.questions?.[0]?.questionText === quizBody.questions[0].questionText);

    const serialised = JSON.stringify(quiz.data ?? {});
    check('fetched quiz hides multiple-choice answer keys',
      !/correctOption|correct_option/.test(serialised));
    check('fetched quiz hides open-ended model answers',
      !/modelAnswer|model_answer|Solar/.test(serialised));

    const [q1, q2, q3] = quiz.data?.questions ?? [];

    const emptyAttempt = await call('POST', `/quizzes/${quizId}/attempts`, {
      token: studentToken,
      body: { answers: [] },
    });
    check('attempt with no answers rejected', emptyAttempt.status === 400);

    const missingQuizAttempt = await call('POST', '/quizzes/999999/attempts', {
      token: studentToken,
      body: { answers: [{ questionId: 1, selectedOption: 0 }] },
    });
    check('attempt on a missing quiz returns 404', missingQuizAttempt.status === 404);

    // Q1 correct (1), Q2 wrong (picks 1, key is 0), open-ended is not graded.
    const attempt = await call('POST', `/quizzes/${quizId}/attempts`, {
      token: studentToken,
      body: {
        answers: [
          { questionId: q1?.questionId, selectedOption: 1 },
          { questionId: q2?.questionId, selectedOption: 1 },
          { questionId: q3?.questionId, freeTextAnswer: 'Wind' },
        ],
      },
    });
    check('student can submit an attempt', attempt.status === 201 && typeof attempt.data?.attemptId === 'number');
    check('score is 50 (1 of 2 multiple-choice correct)', attempt.data?.score === 50,
      `got ${attempt.data?.score}`);
    check('only multiple-choice questions are graded', attempt.data?.totalGraded === 2,
      `got ${attempt.data?.totalGraded}`);

    const byQuestion = (id) => attempt.data?.results?.find((r) => r.questionId === id);
    check('correct answer marked correct', byQuestion(q1?.questionId)?.isCorrect === true);
    check('wrong answer marked incorrect', byQuestion(q2?.questionId)?.isCorrect === false);
    check('attempt reveals the correct option for a wrong answer',
      byQuestion(q2?.questionId)?.correctOption === 0);
    check('open-ended answer is not auto-graded', byQuestion(q3?.questionId)?.isCorrect === null);
    check('attempt reveals the open-ended model answer', byQuestion(q3?.questionId)?.modelAnswer === 'Solar');

    const perfect = await call('POST', `/quizzes/${quizId}/attempts`, {
      token: studentToken,
      body: {
        answers: [
          { questionId: q1?.questionId, selectedOption: 1 },
          { questionId: q2?.questionId, selectedOption: 0 },
        ],
      },
    });
    check('a second attempt is allowed and scores 100', perfect.status === 201 && perfect.data?.score === 100,
      `got ${perfect.data?.score}`);

    const studentDelete = await call('DELETE', `/quizzes/${quizId}`, { token: studentToken });
    check('student cannot delete quizzes', studentDelete.status === 403);

    const lecturerDelete = await call('DELETE', `/quizzes/${quizId}`, { token: lecturerToken });
    check('lecturer cannot delete quizzes (admin only)', lecturerDelete.status === 403);

    const adminDelete = await call('DELETE', `/quizzes/${quizId}`, { token: adminToken });
    check('admin can delete a quiz', adminDelete.status === 204);
    if (adminDelete.status === 204) createdQuizIds.splice(createdQuizIds.indexOf(quizId), 1);

    const afterDelete = await call('GET', `/quizzes/${quizId}`, { token: studentToken });
    check('deleted quiz returns 404', afterDelete.status === 404);

    const deleteAgain = await call('DELETE', `/quizzes/${quizId}`, { token: adminToken });
    check('deleting a missing quiz returns 404', deleteAgain.status === 404);
  } finally {
    for (const id of createdQuizIds) {
      await call('DELETE', `/quizzes/${id}`, { token: adminToken });
    }
    for (const id of createdEventIds) {
      await call('DELETE', `/events/${id}`, { token: adminToken });
    }
  }

  console.log(`\n${passed} passed, ${failed} failed\n`);
  process.exitCode = failed === 0 ? 0 : 1;
}

run().catch((err) => {
  console.error('\nSmoke test could not run:', err.message);
  console.error('Is the server running? Start it with: npm run dev');
  process.exitCode = 1;
});
