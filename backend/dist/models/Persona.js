"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const sequelize_1 = require("sequelize");
const database_1 = __importDefault(require("../config/database"));
class Persona extends sequelize_1.Model {
}
Persona.init({
    id: { type: sequelize_1.DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    tenant_id: { type: sequelize_1.DataTypes.INTEGER, allowNull: false },
    name: { type: sequelize_1.DataTypes.STRING, allowNull: false },
    role: { type: sequelize_1.DataTypes.STRING, allowNull: false },
    tone: { type: sequelize_1.DataTypes.STRING, allowNull: false },
    language: { type: sequelize_1.DataTypes.STRING },
    knowledge_base: { type: sequelize_1.DataTypes.JSON },
    tools: { type: sequelize_1.DataTypes.JSON },
    is_template: { type: sequelize_1.DataTypes.BOOLEAN, defaultValue: false },
    vapi_assistant_id: { type: sequelize_1.DataTypes.STRING },
    calendar_config: { type: sequelize_1.DataTypes.JSON },
    whatsapp_config: { type: sequelize_1.DataTypes.JSON },
}, { sequelize: database_1.default, modelName: 'persona' });
exports.default = Persona;
