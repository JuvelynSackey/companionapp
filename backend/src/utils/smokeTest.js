/**
 * End-to-end smoke test against a running server.
 *
 *   node src/utils/smokeTest.js
 *
 * Walks the whole student journey from the proposal's system-testing example
 * (login -> dashboard -> schedule -> grades -> events) plus the admin paths,
 * and checks that authorisation is actually enforced rather than assumed.
 */
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

  console.log(`\n${passed} passed, ${failed} failed\n`);
  process.exitCode = failed === 0 ? 0 : 1;
}

run().catch((err) => {
  console.error('\nSmoke test could not run:', err.message);
  console.error('Is the server running? Start it with: npm run dev');
  process.exitCode = 1;
});
