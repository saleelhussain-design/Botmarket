"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseFile = void 0;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const pdf2json = require('pdf2json');
const parseFile = async (filePath) => {
    const ext = path_1.default.extname(filePath).toLowerCase();
    if (ext === '.pdf') {
        return new Promise((resolve, reject) => {
            const pdfParser = new pdf2json();
            pdfParser.on("event", (errDesc, textParsed) => {
                if (errDesc) {
                    reject(new Error(errDesc));
                }
                else if (textParsed) {
                    // pdf2json returns a complex object, we just want the text
                    // This is a simplification for the demo
                    resolve(textParsed.Pages[0].Texts.map((t) => t.Text).join(" "));
                }
            });
            pdfParser.parseFile(filePath);
        });
    }
    // default to plain text
    return await fs_1.default.promises.readFile(filePath, 'utf-8');
};
exports.parseFile = parseFile;
