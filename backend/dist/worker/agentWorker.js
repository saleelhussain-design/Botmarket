"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const Persona_1 = __importDefault(require("../models/Persona"));
const database_1 = __importDefault(require("../config/database"));
async function runAgent(personaId) {
    try {
        await database_1.default.authenticate();
        const persona = await Persona_1.default.findByPk(personaId);
        if (!persona) {
            console.error(`[Worker] Persona ${personaId} not found.`);
            process.exit(1);
        }
        console.log(`[Worker] Agent "${persona.name}" (ID: ${persona.id}) started.`);
        console.log(`[Worker] Role: ${persona.role}, Tone: ${persona.tone}`);
        // --- Task 4.3: Welcome Sequence ---
        console.log(`[${new Date().toISOString()}] [Agent:${persona.id}] 👋 Performing Welcome Sequence...`);
        console.log(`[${new Date().toISOString()}] [Agent:${persona.id}] 💌 Sending welcome message: "Hello! I am ${persona.name}, your new ${persona.role}. I'm ready to help!"`);
        console.log(`[${new Date().toISOString()}] [Agent:${persona.id}] ✅ Welcome sequence complete.`);
        // ---------------------------------
        // Simulate agent "listening"
        setInterval(() => {
            const timestamp = new Date().toISOString();
            console.log(`[${timestamp}] [Agent:${persona.id}] Listening for ${persona.tools?.join(', ') || 'messages'}...`);
        }, 10000);
    }
    catch (error) {
        console.error(`[Worker] Error:`, error);
        process.exit(1);
    }
}
// Handle process termination
process.on('SIGINT', () => {
    console.log('[Worker] Agent shutting down...');
    process.exit();
});
// For testing via CLI
const personaIdArg = process.argv[2];
if (personaIdArg) {
    const id = parseInt(personaIdArg);
    if (isNaN(id)) {
        console.error('[Worker] Invalid Persona ID provided.');
        process.exit(1);
    }
    runAgent(id);
}
