import { Router } from 'express';

import authRoutes from './authRoutes.js';
import { requireAuth, requireAdmin } from '../middleware/auth.js';
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
  createAnnouncementSchema,
} from '../controllers/announcementController.js';
import {
  listEvents, createEvent, registerForEvent, cancelRegistration,
  createEventSchema,
} from '../controllers/eventController.js';
import { listClubs, joinClub, leaveClub } from '../controllers/clubController.js';
import { listLocations, listCategories } from '../controllers/locationController.js';
import { listCourses } from '../controllers/courseController.js';

const router = Router();

// ---- Module 1: authentication (public) ----
router.use('/auth', authRoutes);

// Everything below requires a valid token.
router.use(requireAuth);

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

// ---- Module 4: grades & performance ----
router.get('/grades', listGrades);
router.post('/grades', requireAdmin, validateBody(upsertGradeSchema), upsertGrade);

// ---- Module 5: events & clubs ----
router.get('/events', listEvents);
router.post('/events', requireAdmin, validateBody(createEventSchema), createEvent);
router.post('/events/:id/register', registerForEvent);
router.delete('/events/:id/register', cancelRegistration);

router.get('/clubs', listClubs);
router.post('/clubs/:id/join', joinClub);
router.delete('/clubs/:id/join', leaveClub);

// ---- Module 6: campus map ----
router.get('/locations', listLocations);
router.get('/locations/categories', listCategories);

export default router;
