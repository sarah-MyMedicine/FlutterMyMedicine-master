const crypto = require('crypto');

const isProduction = process.env.NODE_ENV === 'production';

const insecureSecretValues = new Set([
  '',
  'your-secret-key-change-in-production',
  'your-super-secret-jwt-key-change-this-in-production',
  'your-super-secret-admin-key-change-this-in-production',
  'admin-secret-key-change-this-12345',
]);

function readNumber(name, fallback) {
  const raw = process.env[name];
  if (!raw || !raw.trim()) {
    return fallback;
  }

  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseOrigins(raw) {
  if (!raw || !raw.trim()) {
    return [];
  }

  return raw
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
}

const config = {
  isProduction,
  nodeEnv: process.env.NODE_ENV || 'development',
  host: process.env.HOST || '0.0.0.0',
  port: readNumber('PORT', 5000),
  jwtSecret: process.env.JWT_SECRET || 'your-secret-key-change-in-production',
  adminApiKey: process.env.ADMIN_API_KEY || '',
  firebaseWebApiKey: process.env.FIREBASE_WEB_API_KEY || process.env.FIREBASE_API_KEY || '',
  corsAllowedOrigins: parseOrigins(process.env.CORS_ALLOWED_ORIGINS),
  requestBodyLimit: process.env.REQUEST_BODY_LIMIT || '25mb',
  trustProxy: process.env.TRUST_PROXY || '1',
  keepAliveTimeoutMs: readNumber('KEEP_ALIVE_TIMEOUT_MS', 65000),
  headersTimeoutMs: readNumber('HEADERS_TIMEOUT_MS', 66000),
  requestTimeoutMs: readNumber('REQUEST_TIMEOUT_MS', 30000),
  appVersion: process.env.APP_VERSION || '1.0.0',
  releaseId: process.env.RELEASE_ID || crypto.randomUUID(),
  // SMTP (nodemailer) — used for sending password-reset emails
  smtpHost: process.env.SMTP_HOST || '',
  smtpPort: readNumber('SMTP_PORT', 587),
  smtpSecure: process.env.SMTP_SECURE === 'true',
  smtpUser: process.env.SMTP_USER || '',
  smtpPass: process.env.SMTP_PASS || '',
  smtpFrom: process.env.SMTP_FROM || 'My Medicine <noreply@mymedicine.app>',
};

function assertValidConfig() {
  const errors = [];
  const warnings = [];

  if (!config.jwtSecret) {
    errors.push('JWT_SECRET is required.');
  }

  if (!config.adminApiKey) {
    warnings.push('ADMIN_API_KEY is not set. Admin routes will reject all requests.');
  }

  if (!config.firebaseWebApiKey) {
    warnings.push('FIREBASE_WEB_API_KEY is not set. Firebase email/password login will fail.');
  }

  if (!config.smtpHost || !config.smtpUser || !config.smtpPass) {
    warnings.push('SMTP_HOST / SMTP_USER / SMTP_PASS are not set. Password reset emails will not be delivered.');
  }

  if (config.isProduction && insecureSecretValues.has(config.jwtSecret)) {
    errors.push('JWT_SECRET must be a strong unique value in production.');
  }

  if (config.isProduction && insecureSecretValues.has(config.adminApiKey)) {
    errors.push('ADMIN_API_KEY must be a strong unique value in production.');
  }

  if (config.isProduction && config.corsAllowedOrigins.length === 0) {
    warnings.push('CORS_ALLOWED_ORIGINS is empty. This is fine for native mobile clients, but set it before serving web clients.');
  }

  if (errors.length > 0) {
    throw new Error(errors.join(' '));
  }

  warnings.forEach((warning) => {
    console.warn(`[Config] ${warning}`);
  });
}

function corsOptionsDelegate(req, callback) {
  const origin = req.header('Origin');

  if (!origin) {
    callback(null, { origin: true, credentials: true });
    return;
  }

  if (!config.isProduction || config.corsAllowedOrigins.length === 0) {
    callback(null, { origin: true, credentials: true });
    return;
  }

  if (config.corsAllowedOrigins.includes(origin)) {
    callback(null, { origin: true, credentials: true });
    return;
  }

  callback(new Error(`Origin ${origin} is not allowed by CORS`));
}

module.exports = {
  config,
  assertValidConfig,
  corsOptionsDelegate,
};