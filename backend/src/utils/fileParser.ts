import fs from 'fs';
import path from 'path';
const pdf2json = require('pdf2json');

export const parseFile = async (filePath: string): Promise<string> => {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.pdf') {
    return new Promise((resolve, reject) => {
      const pdfParser = new pdf2json();
      pdfParser.on("event", (errDesc: any, textParsed: any) => {
        if (errDesc) {
          reject(new Error(errDesc));
        } else if (textParsed) {
          // pdf2json returns a complex object, we just want the text
          // This is a simplification for the demo
          resolve(textParsed.Pages[0].Texts.map((t: any) => t.Text).join(" "));
        }
      });
      pdfParser.parseFile(filePath);
    });
  }
  // default to plain text
  return await fs.promises.readFile(filePath, 'utf-8');
};

