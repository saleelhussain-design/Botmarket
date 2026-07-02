"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const personaRoutes_1 = __importDefault(require("./routes/personaRoutes"));
const integrationRoutes_1 = __importDefault(require("./routes/integrationRoutes"));
const whatsappRoutes_1 = __importDefault(require("./routes/whatsappRoutes"));
const wizardRoutes_1 = __importDefault(require("./routes/wizardRoutes"));
const marketingRoutes_1 = __importDefault(require("./routes/marketingRoutes"));
const salesRoutes_1 = __importDefault(require("./routes/salesRoutes"));
const dashboardRoutes_1 = __importDefault(require("./routes/dashboardRoutes"));
const database_1 = __importDefault(require("./config/database"));
const app = (0, express_1.default)();
const PORT = Number(process.env.PORT) || 3001;
app.use((0, cors_1.default)({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express_1.default.json());
// Routes
app.use('/api', personaRoutes_1.default);
app.use('/api/integrations', integrationRoutes_1.default);
app.use('/api/whatsapp', whatsappRoutes_1.default);
app.use('/api/wizard', wizardRoutes_1.default);
app.use('/api/marketing', marketingRoutes_1.default);
app.use('/api/sales', salesRoutes_1.default);
app.use('/api/dashboard', dashboardRoutes_1.default);
// Health Check
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
});
const startServer = async () => {
    try {
        await database_1.default.sync({ force: false });
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
