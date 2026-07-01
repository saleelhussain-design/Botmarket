"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const personaRoutes_1 = __importDefault(require("./routes/personaRoutes"));
const integrationRoutes_1 = __importDefault(require("./routes/integrationRoutes"));
const whatsappRoutes_1 = __importDefault(require("./routes/whatsappRoutes"));
const database_1 = __importDefault(require("./config/database"));
const app = (0, express_1.default)();
const PORT = Number(process.env.PORT) || 3001;
app.use(express_1.default.json());
// Routes
app.use('/api', personaRoutes_1.default);
app.use('/api/integrations', integrationRoutes_1.default);
app.use('/api/whatsapp', whatsappRoutes_1.default);
// Health Check
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});
const startServer = async () => {
    try {
        await database_1.default.sync({ force: true });
        console.log('Database synced successfully.');
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Backend server running at http://0.0.0.0:${PORT}`);
        });
    }
    catch (error) {
        console.error('Unable to sync database:', error);
        process.exit(1);
    }
};
startServer();
