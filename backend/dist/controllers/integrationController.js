"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateCalendarConfig = exports.createVapiAssistant = void 0;
const Persona_1 = __importDefault(require("../models/Persona"));
const axios_1 = __importDefault(require("axios"));
const VAPI_API_KEY = process.env.VAPI_API_KEY || 'your_vapi_key';
const createVapiAssistant = async (req, res) => {
    const { personaId } = req.params;
    try {
        const persona = await Persona_1.default.findByPk(personaId);
        if (!persona) {
            return res.status(404).json({ message: 'Persona not found' });
        }
        const response = await axios_1.default.post('https://api.vapi.ai/assistant', {
            name: persona.name,
            firstMessage: `Hello, I am ${persona.name}, your ${persona.role}. How can I help you today?`,
            model: {
                provider: 'openai',
                model: 'gpt-4',
                messages: [
                    {
                        role: 'system',
                        content: `You are ${persona.name}, a ${persona.role}. Your tone is ${persona.tone}. Knowledge: ${JSON.stringify(persona.knowledge_base)}`,
                    },
                ],
            },
            voice: {
                provider: 'playht',
                voiceId: 'jennifer',
            },
        }, {
            headers: { Authorization: `Bearer ${VAPI_API_KEY}` },
        });
        const assistantId = response.data.id;
        await persona.update({ vapi_assistant_id: assistantId });
        res.status(201).json({
            message: 'Vapi Assistant created and linked',
            assistantId,
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error creating Vapi Assistant',
            error: error.response?.data || error.message,
        });
    }
};
exports.createVapiAssistant = createVapiAssistant;
const updateCalendarConfig = async (req, res) => {
    const { personaId } = req.params;
    try {
        const persona = await Persona_1.default.findByPk(personaId);
        if (!persona) {
            return res.status(404).json({ message: 'Persona not found' });
        }
        await persona.update({ calendar_config: req.body });
        res.status(200).json({
            message: 'Calendar configuration updated',
            calendar_config: persona.calendar_config,
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error updating calendar config',
            error: error.message,
        });
    }
};
exports.updateCalendarConfig = updateCalendarConfig;
