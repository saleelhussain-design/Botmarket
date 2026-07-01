"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.step3Integrations = exports.step2KnowledgeUpload = exports.step1BasicInfo = void 0;
const Persona_1 = __importDefault(require("../models/Persona"));
const fileParser_1 = require("../utils/fileParser");
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
        // Assuming req.body.filePath is passed for simplicity in this demo
        // In production, we'd use multer for file uploads
        const { filePath } = req.body;
        const text = await (0, fileParser_1.parseFile)(filePath);
        const updatedKnowledge = [...(persona.knowledge_base || []), text];
        await persona.update({ knowledge_base: updatedKnowledge });
        res.status(200).json({
            message: 'Step 2 complete: Knowledge ingested',
            knowledgeCount: updatedKnowledge.length,
        });
    }
    catch (error) {
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
        res.status(200).json({
            message: 'Step 3 complete: Integrations configured',
            persona: persona,
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Step 3 failed', error: error.message });
    }
};
exports.step3Integrations = step3Integrations;
