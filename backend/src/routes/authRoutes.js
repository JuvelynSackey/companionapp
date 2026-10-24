import { Router } from 'express';
import {
  register,
  login,
  me,
  googleSignIn,
  registerSchema,
  loginSchema,
  googleSignInSchema,
} from '../controllers/authController.js';
import { validateBody } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.js';

const router = Router();

router.post('/register', validateBody(registerSchema), register);
router.post('/login', validateBody(loginSchema), login);
router.post('/google', validateBody(googleSignInSchema), googleSignIn);
router.get('/me', requireAuth, me);

export default router;
