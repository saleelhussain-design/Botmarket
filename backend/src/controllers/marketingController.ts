import { Request, Response } from 'express';
import { marketingService } from '../services/marketingService';

export const generateContent = async (req: Request, res: Response) => {
  try {
    const { personaId, productName, targetAudience, platform } = req.body;
    
    if (!personaId || !productName || !targetAudience || !platform) {
      return res.status(400).json({ message: 'Missing required parameters: personaId, productName, targetAudience, and platform are required.' });
    }

    const copy = await marketingService.generateMarketingCopy({ 
      personaId: Number(personaId), 
      productName, 
      targetAudience, 
      platform 
    });
    
    res.status(200).json({ 
      message: 'Content generated successfully', 
      copy 
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Content generation failed', error: error.message });
  }
};

export const scrapeLeads = async (req: Request, res: Response) => {
  try {
    const { source, query } = req.body;
    
    if (!source || !query) {
      return res.status(400).json({ message: 'Missing required parameters: source and query are required.' });
    }

    const leads = await marketingService.scrapeBusinessLeads(source, query);
    res.status(200).json({ 
      message: 'Leads scraped successfully', 
      source, 
      query, 
      leads 
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Lead scraping failed', error: error.message });
  }
};
