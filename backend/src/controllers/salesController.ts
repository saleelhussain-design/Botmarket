import { Request, Response } from 'express';
import { salesService } from '../services/salesService';

export const createPrototype = async (req: Request, res: Response) => {
  try {
    const { leadName, businessName, industry, targetGoal } = req.body;

    if (!leadName || !businessName || !industry) {
      return res.status(400).json({ message: 'Missing required parameters: leadName, businessName, and industry are required.' });
    }

    const result = await salesService.generatePrototype({
      leadName,
      businessName,
      industry,
      targetGoal
    });

    res.status(201).json(result);
  } catch (error: any) {
    res.status(500).json({ message: 'Prototype generation failed', error: error.message });
  }
};

export const getROICalculation = async (req: Request, res: Response) => {
  try {
    const { monthlyCalls, averageTicketValue } = req.query;
    
    const result = await salesService.calculateROI(
      Number(monthlyCalls) || 0,
      Number(averageTicketValue) || 0
    );
    
    res.status(200).json(result);
  } catch (error: any) {
    res.status(500).json({ message: 'ROI calculation failed', error: error.message });
  }
};
