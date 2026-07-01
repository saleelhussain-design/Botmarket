"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateWhatsappConfig = void 0;
const Persona_1 = __importDefault(require("../models/Persona"));
const updateWhatsappConfig = async (req, res) => {
    const { personaId } = req.params;
    try {
        const persona = await Persona_1.default.findByPk(personaId);
        if (!persona) {
            return res.status(404).json({ message: 'Persona not found' });
        }
        await persona.update({ whatsapp_config: req.body });
        res.status(200).json({
            message: 'WhatsApp configuration updated',
            whatsapp_config: persona.whatsapp_config,
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error updating WhatsApp config',
            error: error.message,
        });
    }
};
exports.updateWhatsappConfig = updateWhatsappConfig;
