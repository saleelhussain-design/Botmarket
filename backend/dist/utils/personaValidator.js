"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.validatePersona = void 0;
const ajv_1 = __importDefault(require("ajv"));
const persona_schema_json_1 = __importDefault(require("../schemas/persona.schema.json"));
const ajv = new ajv_1.default();
const validate = ajv.compile(persona_schema_json_1.default);
const validatePersona = (data) => {
    const valid = validate(data);
    if (!valid) {
        return {
            isValid: false,
            errors: validate.errors,
        };
    }
    return { isValid: true, errors: null };
};
exports.validatePersona = validatePersona;
