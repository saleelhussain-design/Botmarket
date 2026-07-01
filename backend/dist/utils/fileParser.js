"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseFile = void 0;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const pdf = require('pdf-parse');
const parseFile = async (filePath) => {
    const ext = path_1.default.extname(filePath).toLowerCase();
    if (ext === '.pdf') {
        const data = await fs_1.default.promises.readFile(filePath);
        const parsed = await pdf(data);
        return parsed.text;
    }
    // default to plain text
    return await fs_1.default.promises.readFile(filePath, 'utf-8');
};
exports.parseFile = parseFile;
