const express = require('express');
const http = require('http');
const os = require('os');
const compression = require('compression');
const cors = require('cors');
const dotenv = require('dotenv');
const helmet = require('helmet');

// Load environment variables
dotenv.config();

const { config, assertValidConfig, corsOptionsDelegate } = require('./config/env');
const { initializeFirebaseAdmin } = require('./services/firebase_admin_service');

assertValidConfig();

// Create Express app
const app = express();
const HOST = config.host;

app.disable('x-powered-by');
app.set('trust proxy', config.trustProxy);

// Middleware
app.use(
  helmet({
    crossOriginResourcePolicy: false,
  }),
);
app.use(compression());
app.use(cors(corsOptionsDelegate));
app.use(express.json({ limit: config.requestBodyLimit }));

app.use((req, res, next) => {
  res.setHeader('X-Backend-Instance', os.hostname());
  next();
});

const firebaseConfigured = initializeFirebaseAdmin();
if (!firebaseConfigured) {
  console.warn('[Server] Firebase Admin is not configured. Firestore-backed routes will fail until credentials are provided.');
}

// ============ ROUTES ============

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Server is running',
    uptimeSeconds: Math.floor(process.uptime()),
    firebaseConfigured,
    version: config.appVersion,
    releaseId: config.releaseId,
  });
});

app.get('/api/health', (req, res) => {
  res.status(firebaseConfigured ? 200 : 503).json({
    status: firebaseConfigured ? 'ok' : 'degraded',
    message: firebaseConfigured
        ? 'API is healthy'
        : 'API is running but Firebase Admin is not configured',
    uptimeSeconds: Math.floor(process.uptime()),
    firebaseConfigured,
    host: HOST,
    version: config.appVersion,
    releaseId: config.releaseId,
  });
});

app.get('/', (req, res) => {
  res.json({
    service: 'mymedicine-backend',
    status: 'ok',
    health: '/api/health',
    version: config.appVersion,
  });
});

// Authentication routes
app.use('/api/auth', require('./routes/auth'));

// Caregiver routes
app.use('/api/caregiver', require('./routes/caregiver'));

// Patient data sync routes
app.use('/api/patient-data', require('./routes/patient_data'));

// Admin routes (protected by API key)
app.use('/api/admin', require('./routes/admin'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  if (err?.message?.includes('not allowed by CORS')) {
    return res.status(403).json({ message: 'CORS origin not allowed' });
  }

  console.error('[Error Handler]', err);
  res.status(500).json({ message: 'Internal server error' });
});

// ============ START SERVER ============

const PORT = config.port;
const server = http.createServer(app);

server.keepAliveTimeout = config.keepAliveTimeoutMs;
server.headersTimeout = config.headersTimeoutMs;
server.requestTimeout = config.requestTimeoutMs;

server.listen(PORT, HOST, () => {
  const interfaces = Object.values(os.networkInterfaces())
      .flat()
      .filter((entry) => entry && entry.family === 'IPv4' && !entry.internal)
      .map((entry) => entry.address);

  console.log(`[Server] Running on http://${HOST}:${PORT}`);
  console.log(`[Environment] ${config.nodeEnv}`);
  console.log(`[Release] ${config.releaseId}`);
  if (interfaces.length > 0) {
    console.log('[Server] Reachable LAN URLs:');
    interfaces.forEach((ip) => {
      console.log(`  http://${ip}:${PORT}/api`);
    });
  }
});

const shutdown = (signal) => {
  console.log(`[Server] Received ${signal}, shutting down`);
  server.close(() => {
    process.exit(0);
  });
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

module.exports = app;
