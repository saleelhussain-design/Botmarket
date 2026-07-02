"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.step3Integrations = exports.step2KnowledgeUpload = exports.step1BasicInfo = void 0;
const Persona_1 = __importDefault(require("../models/Persona"));
const fileParser_1 = require("../utils/fileParser");
const child_process_1 = require("child_process");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const step1BasicInfo = async (req, res) => {
    try {
        const { name, role, tone, tenant_id } = req.body;
        const persona = await Persona_1.default.create({
            name,
            role,
            tone,
            tenant_id: tenant_id || 1,
        });
        res.status(201).json({
            message: 'Step 1 complete: Persona created',
            personaId: persona.id,
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Step 1 failed', error: error.message });
    }
};
exports.step1BasicInfo = step1BasicInfo;
const step2KnowledgeUpload = async (req, res) => {
    const { personaId } = req.params;
    try {
        const persona = await Persona_1.default.findByPk(personaId);
        if (!persona)
            return res.status(404).json({ message: 'Persona not found' });
        const { filePath } = req.body;
        // Resolve absolute path if a relative one is provided
        const absolutePath = path_1.default.isAbsolute(filePath)
            ? filePath
            : path_1.default.join(process.cwd(), filePath);
        console.log(`Attempting to parse file at: ${absolutePath}`);
        if (!fs_1.default.existsSync(absolutePath)) {
            throw new Error(`File not found at ${absolutePath}`);
        }
        const text = await (0, fileParser_1.parseFile)(absolutePath);
        const updatedKnowledge = [...(persona.knowledge_base || []), text];
        await persona.update({ knowledge_base: updatedKnowledge });
        res.status(200).json({
            message: 'Step 2 complete: Knowledge ingested',
            knowledgeCount: updatedKnowledge.length,
        });
    }
    catch (error) {
        console.error(`Step 2 Error: ${error.message}`);
        res.status(500).json({ message: 'Step 2 failed', error: error.message });
    }
};
exports.step2KnowledgeUpload = step2KnowledgeUpload;
const step3Integrations = async (req, res) => {
    const { personaId } = req.params;
    try {
        const persona = await Persona_1.default.findByPk(personaId);
        if (!persona)
            return res.status(404).json({ message: 'Persona not found' });
        const { vapi, whatsapp, calendar } = req.body;
        const updates = {};
        if (calendar)
            updates.calendar_config = calendar;
        if (whatsapp)
            updates.whatsapp_config = whatsapp;
        await persona.update(updates);
        if (vapi) {
            console.log(`Triggering Vapi provisioning for persona ${personaId}`);
        }
        // --- DEPLOYMENT LOGIC ---
        const workerDir = '/home/saleel/botmarket/backend/workers';
        if (!fs_1.default.existsSync(workerDir)) {
            fs_1.default.mkdirSync(workerDir, { recursive: true });
        }
        const workerCmd = `node /home/saleel/botmarket/backend/dist/worker/agentWorker.js ${personaId} > ${workerDir}/agent_${personaId}.log 2>&1 &`;
        (0, child_process_1.exec)(workerCmd, (error) => {
            if (error)
                console.error(`Deployment failed for ${personaId}:`, error);
        });
        res.status(200).json({
            message: 'Step 3 complete: Agent Deployed!',
            persona: persona,
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Step 3 failed', error: error.message });
    }
};
exports.step3Integrations = step3Integrations;
