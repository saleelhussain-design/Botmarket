import { Router } from 'express';
import { createPersona, getPersonas, clonePersona } from '../controllers/personaController';

const router = Router();

router.post('/personas', createPersona);
router.get('/personas', getPersonas);
router.post('/personas/:id/clone', clonePersona);

export default router;
