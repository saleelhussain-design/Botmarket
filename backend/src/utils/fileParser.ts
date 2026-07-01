import fs from 'fs';
import path from 'path';
const pdf = require('pdf-parse');

export const parseFile = async (filePath: string): Promise<string> => {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.pdf') {
    const data = await fs.promises.readFile(filePath);
    const parsed = await pdf(data);
    return parsed.text;
  }
  // default to plain text
  return await fs.promises.readFile(filePath, 'utf-8');
};
