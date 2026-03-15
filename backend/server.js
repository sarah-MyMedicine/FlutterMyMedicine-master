const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const User = require('./models/User');

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

// ============ ROUTES ============

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Authentication routes
app.use('/api/auth', require('./routes/auth'));

// Caregiver routes
app.use('/api/caregiver', require('./routes/caregiver'));

// Admin routes (protected by API key)
app.use('/api/admin', require('./routes/admin'));

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
