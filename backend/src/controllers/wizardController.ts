import { Request, Response } from 'express';
import Persona from '../models/Persona';
import { parseFile } from '../utils/fileParser';
import { exec } from 'child_process';
import fs from 'fs';

export const step1BasicInfo = async (req: Request, res: Response) => {
  try {
    const { name, role, tone, tenant_id } = req.body;
    const persona = await Persona.create({
      name,
      role,
      tone,
      tenant_id: tenant_id || 1,
    });
    res.status(201).json({
      message: 'Step 1 complete: Persona created',
      personaId: persona.id,
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Step 1 failed', error: error.message });
  }
};

export const step2KnowledgeUpload = async (req: Request, res: Response) => {
  const { personaId } = req.params;
  try {
    const persona = await Persona.findByPk(personaId as any);
    if (!persona) return res.status(404).json({ message: 'Persona not found' });

    // Assuming req.body.filePath is passed for simplicity in this demo
    // In production, we'd use multer for file uploads
    const { filePath } = req.body;
    const text = await parseFile(filePath);
    
    const updatedKnowledge = [...(persona.knowledge_base || []), text];
    await persona.update({ knowledge_base: updatedKnowledge });

    res.status(200).json({
      message: 'Step 2 complete: Knowledge ingested',
      knowledgeCount: updatedKnowledge.length,
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Step 2 failed', error: error.message });
  }
};

export const step3Integrations = async (req: Request, res: Response) => {
  const { personaId } = req.params;
  try {
    const persona = await Persona.findByPk(personaId as any);
    if (!persona) return res.status(404).json({ message: 'Persona not found' });

    const { vapi, whatsapp, calendar } = req.body;
    const updates: any = {};
    if (calendar) updates.calendar_config = calendar;
    if (whatsapp) updates.whatsapp_config = whatsapp;

    await persona.update(updates);

    if (vapi) {
      console.log(`Triggering Vapi provisioning for persona ${personaId}`);
    }

    // --- DEPLOYMENT LOGIC ---
    // Spawn an isolated worker process for this agent
    const workerDir = '/home/saleel/botmarket/backend/workers';
    if (!fs.existsSync(workerDir)) {
      fs.mkdirSync(workerDir, { recursive: true });
    }

    const workerCmd = `node /home/saleel/botmarket/backend/dist/worker/agentWorker.js ${personaId} > ${workerDir}/agent_${personaId}.log 2>&1 &`;
    
    exec(workerCmd, (error) => {
      if (error) console.error(`Deployment failed for ${personaId}:`, error);
    });

    res.status(200).json({
      message: 'Step 3 complete: Agent Deployed!',
      persona: persona,
    });
  } catch (error: any) {
    res.status(500).json({ message: 'Step 3 failed', error: error.message });
  }
};
