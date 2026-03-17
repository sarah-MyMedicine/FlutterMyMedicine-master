const express = require('express');
const http = require('http');
const os = require('os');
const mongoose = require('mongoose');
const compression = require('compression');
const cors = require('cors');
const dotenv = require('dotenv');
const helmet = require('helmet');
const User = require('./models/User');
const { config, assertValidConfig, corsOptionsDelegate } = require('./config/env');

// Load environment variables
dotenv.config();
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

// MongoDB Connection
const MONGO_URI = config.mongoUri;

mongoose
  .connect(MONGO_URI, {
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
    maxPoolSize: 10,
    family: 4,
  })
  .then(async () => {
    console.log('[MongoDB] Connected successfully');

    // Keep DB indexes aligned with current schemas.
    // This removes stale indexes from old schema versions (e.g. unique email index).
    try {
      await User.syncIndexes();
      console.log('[MongoDB] User indexes synced');
    } catch (indexError) {
      console.error('[MongoDB] Failed to sync User indexes:', indexError);
    }
  })
  .catch((error) => {
    console.error('[MongoDB] Connection failed:', error);
    process.exit(1);
  });

mongoose.connection.on('disconnected', () => {
  console.warn('[MongoDB] Disconnected');
});

mongoose.connection.on('reconnected', () => {
  console.log('[MongoDB] Reconnected');
});

mongoose.connection.on('error', (error) => {
  console.error('[MongoDB] Runtime error:', error);
});

// ============ ROUTES ============

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Server is running',
    uptimeSeconds: Math.floor(process.uptime()),
    mongoReadyState: mongoose.connection.readyState,
    version: config.appVersion,
    releaseId: config.releaseId,
  });
});

app.get('/api/health', (req, res) => {
  const mongoConnected = mongoose.connection.readyState === 1;
  res.status(mongoConnected ? 200 : 503).json({
    status: mongoConnected ? 'ok' : 'degraded',
    message: mongoConnected
        ? 'API is healthy'
        : 'API is running but MongoDB is not connected',
    uptimeSeconds: Math.floor(process.uptime()),
    mongoReadyState: mongoose.connection.readyState,
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
  server.close(async () => {
    try {
      await mongoose.connection.close();
    } finally {
      process.exit(0);
    }
  });
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

module.exports = app;
