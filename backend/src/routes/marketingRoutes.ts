import { Router } from 'express';
import { generateContent, scrapeLeads } from '../controllers/marketingController';

const router = Router();

router.post('/generate-content', generateContent);
router.post('/scrape-leads', scrapeLeads);

export default router;
