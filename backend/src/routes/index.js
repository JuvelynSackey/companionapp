import { Router } from 'express';

import authRoutes from './authRoutes.js';
import { requireAuth, optionalAuth, requireAdmin, requireRole } from '../middleware/auth.js';
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
  listEvents, createEvent, deleteEvent, registerForEvent, cancelRegistration,
  createEventSchema,
} from '../controllers/eventController.js';
import { listClubs, joinClub, leaveClub } from '../controllers/clubController.js';
import { listLocations, listCategories } from '../controllers/locationController.js';
import { listCourses } from '../controllers/courseController.js';
import {
  registerDeviceToken, unregisterDeviceToken, getNotificationPreferences, updateNotificationPreferences,
  registerDeviceTokenSchema, unregisterDeviceTokenSchema, updatePreferencesSchema,
} from '../controllers/deviceController.js';
import {
  listQuizzes, getQuiz, createQuiz, submitAttempt, deleteQuiz,
  createQuizSchema, submitAttemptSchema,
} from '../controllers/quizController.js';
import {
  listLostFound, createLostFound, markReturned, deleteLostFound, createLostFoundSchema,
} from '../controllers/lostFoundController.js';

const router = Router();

// ---- Module 1: authentication (public) ----
router.use('/auth', authRoutes);

// ---- Guest browsing (public reads) ----
// Campus-wide information a visitor may see without an account. A signed-in
// caller still gets their own isRegistered / isMember flags; a guest gets them
// as false. Every write, and everything personal, stays behind requireAuth.
router.get('/announcements', optionalAuth, listAnnouncements);
router.get('/events', optionalAuth, listEvents);
router.get('/clubs', optionalAuth, listClubs);
router.get('/locations', optionalAuth, listLocations);
router.get('/locations/categories', optionalAuth, listCategories);
router.get('/lost-found', optionalAuth, listLostFound);

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
// The mobile app keeps the timetable on the device (student-managed, so its reminders,
// walk-time cards and Today list all work offline) and deliberately does not call the
// /schedule routes. They are kept working and smoke-tested as a possible cloud-backup layer.
router.get('/schedule/today', listToday);
router.post('/schedule', requireAdmin, validateBody(createScheduleSchema), createScheduleEntry);
router.delete('/schedule/:id', requireAdmin, deleteScheduleEntry);

// ---- Module 3: announcements & notifications ----
// GET /announcements is a guest-readable route, declared above requireAuth.
router.post('/announcements', requireAdmin, validateBody(createAnnouncementSchema), createAnnouncement);
router.delete('/announcements/:id', requireAdmin, deleteAnnouncement);
// Declared before no :id route conflicts with "sync-cursor" as a literal segment.
router.get('/announcements/sync-cursor', getSyncCursor);
router.put('/announcements/sync-cursor', validateBody(updateSyncCursorSchema), updateSyncCursor);

// ---- Module 4: grades & performance ----
router.get('/grades', listGrades);
router.post('/grades', requireAdmin, validateBody(upsertGradeSchema), upsertGrade);

// ---- Module 5: events & clubs ----
// GET /events and GET /clubs are guest-readable routes, declared above requireAuth.
// Lecturers/club coordinators and admins may publish events; only admins
// gate the rest of the admin-only surface (schedule, announcements, grades).
router.post('/events', requireRole('lecturer', 'admin'), validateBody(createEventSchema), createEvent);
// Admins delete any event; lecturers only their own (checked in the controller).
router.delete('/events/:id', requireRole('lecturer', 'admin'), deleteEvent);
router.post('/events/:id/register', registerForEvent);
router.delete('/events/:id/register', cancelRegistration);

router.post('/clubs/:id/join', joinClub);
router.delete('/clubs/:id/join', leaveClub);

// ---- Push notifications: this device's token, and the user's on/off preference ----
router.post('/users/me/device-token', validateBody(registerDeviceTokenSchema), registerDeviceToken);
router.delete('/users/me/device-token', validateBody(unregisterDeviceTokenSchema), unregisterDeviceToken);
router.get('/users/me/notification-preferences', getNotificationPreferences);
router.put('/users/me/notification-preferences', validateBody(updatePreferencesSchema), updateNotificationPreferences);

// ---- Module 6: campus map ----
// GET /locations and /locations/categories are guest-readable, declared above requireAuth.

// ---- Module 7: quizzes & learning ----
// Answer key is stripped from getQuiz and only revealed in submitAttempt's
// response — see quizController.js's doc comments on both.
router.get('/quizzes', listQuizzes);
router.get('/quizzes/:id', getQuiz);
router.post('/quizzes', requireRole('lecturer', 'admin'), validateBody(createQuizSchema), createQuiz);
router.post('/quizzes/:id/attempts', validateBody(submitAttemptSchema), submitAttempt);
router.delete('/quizzes/:id', requireAdmin, deleteQuiz);

// ---- Lost & Found board ----
// GET /lost-found is guest-readable (without names or contact details),
// declared above requireAuth. Anyone signed in may post; only the poster or
// an admin may mark an item returned or remove it (checked in the controller).
router.post('/lost-found', validateBody(createLostFoundSchema), createLostFound);
router.patch('/lost-found/:id/returned', markReturned);
router.delete('/lost-found/:id', deleteLostFound);

export default router;
