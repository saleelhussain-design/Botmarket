import express from 'express';
import personaRoutes from './routes/personaRoutes';
import integrationRoutes from './routes/integrationRoutes';
import whatsappRoutes from './routes/whatsappRoutes';
import wizardRoutes from './routes/wizardRoutes';
import sequelize from './config/database';
import Persona from './models/Persona';
import Tenant from './models/Tenant';

const app = express();
const PORT = Number(process.env.PORT) || 3001;

app.use(express.json());

// Routes
app.use('/api', personaRoutes);
app.use('/api/integrations', integrationRoutes);
app.use('/api/whatsapp', whatsappRoutes);
app.use('/api/wizard', wizardRoutes);

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

const startServer = async () => {
  try {
    await sequelize.sync({ force: false });
    console.log('Database synced successfully.');
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Backend server running at http://0.0.0.0:${PORT}`);
    });
  } catch (error) {
    console.error('Unable to sync database:', error);
    process.exit(1);
  }
};

startServer();
