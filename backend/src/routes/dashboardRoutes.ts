import { Router } from 'express';
import { getSystemOverview, getActiveBots, getLLMConfig, updateLLMConfig } from '../controllers/dashboardController';

const router = Router();

router.get('/overview', getSystemOverview);
router.get('/bots', getActiveBots);
router.get('/llm-config', getLLMConfig);
router.post('/llm-config', updateLLMConfig);

export default router;
