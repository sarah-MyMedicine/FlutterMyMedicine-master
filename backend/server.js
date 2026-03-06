const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Create Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/mymedicine';

mongoose
  .connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => {
    console.log('[MongoDB] Connected successfully');
  })
  .catch((error) => {
    console.error('[MongoDB] Connection failed:', error);
    process.exit(1);
  });

// ============ ROUTES ============

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Authentication routes
app.use('/api/auth', require('./routes/auth'));

// Caregiver routes
app.use('/api/caregiver', require('./routes/caregiver'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('[Error Handler]', err);
  res.status(500).json({ message: 'Internal server error' });
});

// ============ START SERVER ============

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`[Server] Running on http://localhost:${PORT}`);
  console.log(`[Environment] ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
