"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const integrationController_1 = require("../controllers/integrationController");
const router = (0, express_1.Router)();
router.post('/personas/:personaId/vapi', integrationController_1.createVapiAssistant);
router.patch('/personas/:personaId/calendar', integrationController_1.updateCalendarConfig);
exports.default = router;
