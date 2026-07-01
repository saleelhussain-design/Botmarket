"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const whatsappController_1 = require("../controllers/whatsappController");
const router = (0, express_1.Router)();
router.patch('/:personaId/whatsapp', whatsappController_1.updateWhatsappConfig);
exports.default = router;
