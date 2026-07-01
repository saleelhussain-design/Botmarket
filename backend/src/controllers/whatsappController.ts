import { Request, Response } from 'express';
import Persona from '../models/Persona';

export const updateWhatsappConfig = async (req: Request, res: Response) => {
  const { personaId } = req.params;
  try {
    const persona = await Persona.findByPk(personaId as any);
    if (!persona) {
      return res.status(404).json({ message: 'Persona not found' });
    }

    await persona.update({ whatsapp_config: req.body });
    res.status(200).json({
      message: 'WhatsApp configuration updated',
      whatsapp_config: persona.whatsapp_config,
    });
  } catch (error: any) {
    res.status(500).json({
      message: 'Error updating WhatsApp config',
      error: error.message,
    });
  }
};
