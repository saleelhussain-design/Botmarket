import { Router } from 'express';
import { createPrototype, getROICalculation } from '../controllers/salesController';

const router = Router();

router.post('/prototype', createPrototype);
router.get('/roi', getROICalculation);

export default router;
