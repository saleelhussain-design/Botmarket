"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const wizardController_1 = require("../controllers/wizardController");
const router = (0, express_1.Router)();
router.post('/start', wizardController_1.step1BasicInfo);
router.post('/:personaId/knowledge', wizardController_1.step2KnowledgeUpload);
router.post('/:personaId/integrations', wizardController_1.step3Integrations);
exports.default = router;
