"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.clonePersona = exports.getPersonas = exports.createPersona = void 0;
const personaValidator_1 = require("../utils/personaValidator");
const Persona_1 = __importDefault(require("../models/Persona"));
const createPersona = async (req, res) => {
    const validation = (0, personaValidator_1.validatePersona)(req.body);
    if (!validation.isValid) {
        return res.status(400).json({
            message: 'Invalid persona data',
            errors: validation.errors,
        });
    }
    try {
        // In a real app, tenant_id would come from the authenticated user's token
        const tenant_id = req.body.tenant_id || 1;
        const newPersona = await Persona_1.default.create({ ...req.body, tenant_id });
        res.status(201).json({
            message: 'Persona created successfully',
            persona: newPersona,
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error creating persona',
            error: error.message,
        });
    }
};
exports.createPersona = createPersona;
const getPersonas = async (req, res) => {
    try {
        // In a real app, filter by req.user.tenant_id
        const tenant_id = req.query.tenant_id ? Number(req.query.tenant_id) : 1;
        const personas = await Persona_1.default.findAll({ where: { tenant_id } });
        res.status(200).json(personas);
    }
    catch (error) {
        res.status(500).json({
            message: 'Error fetching personas',
            error: error.message,
        });
    }
};
exports.getPersonas = getPersonas;
const clonePersona = async (req, res) => {
    const { id } = req.params;
    try {
        const template = await Persona_1.default.findByPk(id);
        if (!template) {
            return res.status(404).json({ message: 'Template not found' });
        }
        const personaData = template.get({ plain: true });
        delete personaData.id;
        personaData.is_template = false;
        // In a real app, inject tenant_id from authenticated user
        personaData.tenant_id = req.query.tenant_id ? Number(req.query.tenant_id) : 1;
        const newPersona = await Persona_1.default.create(personaData);
        res.status(201).json({
            message: 'Persona cloned successfully',
            persona: newPersona,
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error cloning persona',
            error: error.message,
        });
    }
};
exports.clonePersona = clonePersona;
