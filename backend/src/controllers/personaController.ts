import { Request, Response } from 'express';
import { validatePersona } from '../utils/personaValidator';
import Persona from '../models/Persona';

export const createPersona = async (req: Request, res: Response) => {
  const validation = validatePersona(req.body);
  
  if (!validation.isValid) {
    return res.status(400).json({
      message: 'Invalid persona data',
      errors: validation.errors,
    });
  }

  try {
    // In a real app, tenant_id would come from the authenticated user's token
    const tenant_id = req.body.tenant_id || 1; 
    const newPersona = await Persona.create({ ...req.body, tenant_id });
    res.status(201).json({
      message: 'Persona created successfully',
      persona: newPersona,
    });
  } catch (error: any) {
    res.status(500).json({
      message: 'Error creating persona',
      error: error.message,
    });
  }
};

export const getPersonas = async (req: Request, res: Response) => {
  try {
    // In a real app, filter by req.user.tenant_id
    const tenant_id = req.query.tenant_id ? Number(req.query.tenant_id) : 1;
    const personas = await Persona.findAll({ where: { tenant_id } });
    res.status(200).json(personas);
  } catch (error: any) {
    res.status(500).json({
      message: 'Error fetching personas',
      error: error.message,
    });
  }
};

export const clonePersona = async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const template = await Persona.findByPk(id as any);
    if (!template) {
      return res.status(404).json({ message: 'Template not found' });
    }

    const personaData = template.get({ plain: true });
    delete personaData.id;
    personaData.is_template = false;
    // In a real app, inject tenant_id from authenticated user
    personaData.tenant_id = req.query.tenant_id ? Number(req.query.tenant_id) : 1;

    const newPersona = await Persona.create(personaData);
    res.status(201).json({
      message: 'Persona cloned successfully',
      persona: newPersona,
    });
  } catch (error: any) {
    res.status(500).json({
      message: 'Error cloning persona',
      error: error.message,
    });
  }
};
