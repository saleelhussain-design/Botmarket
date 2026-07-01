import { AIPersona } from '../types/persona';

async function runAgent(persona: AIPersona) {
  console.log(`[Worker] Agent "${persona.name}" (ID: ${persona.id}) started.`);
  console.log(`[Worker] Role: ${persona.role}, Tone: ${persona.tone}`);
  
  // Simulate agent "listening"
  setInterval(() => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [Agent:${persona.id}] Listening for ${persona.tools?.join(', ') || 'messages'}...`);
  }, 10000);
}

// Handle process termination
process.on('SIGINT', () => {
  console.log('[Worker] Agent shutting down...');
  process.exit();
});

// For testing via CLI
const personaId = process.argv[2];
if (personaId) {
  console.log(`[Worker] Starting with Persona ID: ${personaId}`);
  // In a real app, we would fetch the full persona from DB here
  runAgent({
    id: parseInt(personaId),
    name: "Mock Agent",
    role: "Mock Role",
    tone: "friendly"
  } as any);
}
