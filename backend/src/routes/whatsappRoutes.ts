import { Router } from 'express';
import { updateWhatsappConfig } from '../controllers/whatsappController';

const router = Router();

router.patch('/:personaId/whatsapp', updateWhatsappConfig);

export default router;
