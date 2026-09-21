import { Router } from 'express';

import authRoutes from './authRoutes.js';
import { requireAuth, requireAdmin, requireRole } from '../middleware/auth.js';
import { validateBody } from '../middleware/validate.js';

import { getDashboard } from '../controllers/dashboardController.js';
import {
  listSchedule, listToday, createScheduleEntry, deleteScheduleEntry,
  createScheduleSchema,
} from '../controllers/scheduleController.js';
import {
  listGrades, upsertGrade, upsertGradeSchema,
} from '../controllers/gradeController.js';
import {
  listAnnouncements, createAnnouncement, deleteAnnouncement,
  getSyncCursor, updateSyncCursor,
  createAnnouncementSchema, updateSyncCursorSchema,
} from '../controllers/announcementController.js';
import { provisionUser, provisionSchema } from '../controllers/authController.js';
import {
  listEvents, createEvent, registerForEvent, cancelRegistration,
  createEventSchema,
} from '../controllers/eventController.js';
import { listClubs, joinClub, leaveClub } from '../controllers/clubController.js';
import { listLocations, listCategories } from '../controllers/locationController.js';
import { listCourses } from '../controllers/courseController.js';
import {
  listQuizzes, getQuiz, createQuiz, submitAttempt, deleteQuiz,
  createQuizSchema, submitAttemptSchema,
} from '../controllers/quizController.js';

const router = Router();

// ---- Module 1: authentication (public) ----
router.use('/auth', authRoutes);

// Everything below requires a valid token.
router.use(requireAuth);

// ---- Admin: provisioning elevated-role accounts (lecturer/admin) ----
// No self-service or invite-link path — an existing admin creates these
// directly, same trust boundary as the original admin seed account.
router.post('/admin/provision-user', requireAdmin, validateBody(provisionSchema), provisionUser);

// ---- Module 2: dashboard & class schedule ----
router.get('/dashboard', getDashboard);
router.get('/courses', listCourses);
router.get('/schedule', listSchedule);
router.get('/schedule/today', listToday);
router.post('/schedule', requireAdmin, validateBody(createScheduleSchema), createScheduleEntry);
router.delete('/schedule/:id', requireAdmin, deleteScheduleEntry);

// ---- Module 3: announcements & notifications ----
router.get('/announcements', listAnnouncements);
router.post('/announcements', requireAdmin, validateBody(createAnnouncementSchema), createAnnouncement);
router.delete('/announcements/:id', requireAdmin, deleteAnnouncement);
// Declared before no :id route conflicts with "sync-cursor" as a literal segment.
router.get('/announcements/sync-cursor', getSyncCursor);
router.put('/announcements/sync-cursor', validateBody(updateSyncCursorSchema), updateSyncCursor);

// ---- Module 4: grades & performance ----
router.get('/grades', listGrades);
router.post('/grades', requireAdmin, validateBody(upsertGradeSchema), upsertGrade);

// ---- Module 5: events & clubs ----
router.get('/events', listEvents);
// Lecturers/club coordinators and admins may publish events; only admins
// gate the rest of the admin-only surface (schedule, announcements, grades).
router.post('/events', requireRole('lecturer', 'admin'), validateBody(createEventSchema), createEvent);
router.post('/events/:id/register', registerForEvent);
router.delete('/events/:id/register', cancelRegistration);

router.get('/clubs', listClubs);
router.post('/clubs/:id/join', joinClub);
router.delete('/clubs/:id/join', leaveClub);

// ---- Module 6: campus map ----
router.get('/locations', listLocations);
router.get('/locations/categories', listCategories);

// ---- Module 7: quizzes & learning ----
// Answer key is stripped from getQuiz and only revealed in submitAttempt's
// response — see quizController.js's doc comments on both.
router.get('/quizzes', listQuizzes);
router.get('/quizzes/:id', getQuiz);
router.post('/quizzes', requireRole('lecturer', 'admin'), validateBody(createQuizSchema), createQuiz);
router.post('/quizzes/:id/attempts', validateBody(submitAttemptSchema), submitAttempt);
router.delete('/quizzes/:id', requireAdmin, deleteQuiz);

export default router;
