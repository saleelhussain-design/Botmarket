import { Router } from 'express';
import { step1BasicInfo, step2KnowledgeUpload, step3Integrations } from '../controllers/wizardController';

const router = Router();

router.post('/start', step1BasicInfo);
router.post('/:personaId/knowledge', step2KnowledgeUpload);
router.post('/:personaId/integrations', step3Integrations);

export default router;
