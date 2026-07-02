"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const personaController_1 = require("../controllers/personaController");
const router = (0, express_1.Router)();
router.post('/personas', personaController_1.createPersona);
router.get('/personas', personaController_1.getPersonas);
router.post('/personas/:id/clone', personaController_1.clonePersona);
exports.default = router;
