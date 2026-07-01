"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
// /home/saleel/botmarket/backend/src/models/Tenant.ts
const sequelize_1 = require("sequelize");
const database_1 = __importDefault(require("../config/database"));
class Tenant extends sequelize_1.Model {
}
Tenant.init({
    id: { type: sequelize_1.DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    name: { type: sequelize_1.DataTypes.STRING, allowNull: false },
    domain: { type: sequelize_1.DataTypes.STRING, unique: true },
    apiKey: { type: sequelize_1.DataTypes.STRING, unique: true },
}, { sequelize: database_1.default, modelName: 'tenant' });
exports.default = Tenant;
