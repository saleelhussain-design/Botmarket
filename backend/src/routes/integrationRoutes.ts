import { Router } from 'express';
import { createVapiAssistant, updateCalendarConfig } from '../controllers/integrationController';

const router = Router();

router.post('/personas/:personaId/vapi', createVapiAssistant);
router.patch('/personas/:personaId/calendar', updateCalendarConfig);

export default router;
