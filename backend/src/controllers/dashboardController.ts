import { Request, Response } from 'express';
import Persona from '../models/Persona';
import fs from 'fs';
import path from 'path';

export const getSystemOverview = async (req: Request, res: Response) => {
  try {
    const totalBots = await Persona.count();
    const activeBots = (await fs.promises.readdir('/home/saleel/botmarket/backend/workers')).length;
    
    res.status(200).json({
      stats: {
        totalPersonas: totalBots,
        activeWorkers: activeBots,
        systemStatus: 'Healthy',
        backendVersion: '1.0.0'
      }
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to fetch overview', error: error.message });
  }
};

export const getActiveBots = async (req: Request, res: Response) => {
  try {
    const personas = await Persona.findAll();
    const workerDir = '/home/saleel/botmarket/backend/workers';
    const logs = fs.existsSync(workerDir) ? await fs.promises.readdir(workerDir) : [];

    const bots = personas.map(p => ({
      id: p.id,
      name: p.name,
      role: p.role,
      status: logs.includes(`agent_${p.id}.log`) ? 'Online' : 'Offline',
      logPath: `/home/saleel/botmarket/backend/workers/agent_${p.id}.log`
    }));

    res.status(200).json(bots);
  } catch (error: any) {
    res.status(500).json({ message: 'Failed to fetch bots', error: error.message });
  }
};

export const getLLMConfig = async (req: Request, res: Response) => {
  // Mock configuration for now. In production, this would be in a 'Config' table.
  const config = {
    defaultModel: 'gpt-4-turbo',
    mappings: [
      { personaId: 1, model: 'gpt-4-turbo', temperature: 0.7 },
      { personaId: 8, model: 'claude-3-opus', temperature: 0.5 },
    ],
    providers: {
      openai: { status: 'connected', apiKey: '************' },
      anthropic: { status: 'connected', apiKey: '************' },
      ollama: { status: 'connected', endpoint: 'http://192.168.1.202:11434' }
    }
  };
  res.status(200).json(config);
};

export const updateLLMConfig = async (req: Request, res: Response) => {
  const { personaId, model } = req.body;
  console.log(`Updating LLM for Persona ${personaId} to ${model}...`);
  res.status(200).json({ message: `LLM updated to ${model} for persona ${personaId}` });
};
