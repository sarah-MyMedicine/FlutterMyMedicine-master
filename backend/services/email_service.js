const nodemailer = require('nodemailer');
const { config } = require('../config/env');

function createTransporter() {
  if (!config.smtpHost || !config.smtpUser || !config.smtpPass) {
    return null;
  }

  return nodemailer.createTransport({
    host: config.smtpHost,
    port: config.smtpPort,
    secure: config.smtpSecure,
    auth: {
      user: config.smtpUser,
      pass: config.smtpPass,
    },
  });
}

/**
 * Sends a password-reset email containing the Firebase-generated one-time link.
 * Throws if SMTP is not configured.
 */
async function sendPasswordResetEmail({ to, resetLink }) {
  const transporter = createTransporter();

  if (!transporter) {
    throw new Error(
      'Email service is not configured. Set SMTP_HOST, SMTP_USER, and SMTP_PASS in environment variables.',
    );
  }

  const from = config.smtpFrom;

  await transporter.sendMail({
    from,
    to,
    subject: 'Reset your My Medicine password',
    html: `
      <div style="font-family: sans-serif; max-width: 520px; margin: 0 auto; padding: 32px; background: #f9f9f9; border-radius: 8px;">
        <h2 style="color: #2e7d32;">Reset your password</h2>
        <p style="color: #333;">We received a request to reset the password for your <strong>My Medicine</strong> account.</p>
        <p style="color: #333;">Click the button below to choose a new password. This link is valid for <strong>1 hour</strong> and can only be used once.</p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${resetLink}"
             style="background-color: #2e7d32; color: white; padding: 14px 32px; text-decoration: none;
                    border-radius: 8px; font-size: 16px; font-weight: bold; display: inline-block;">
            Reset Password
          </a>
        </div>
        <p style="color: #888; font-size: 13px;">If you didn't request this, you can safely ignore this email. Your password will not change.</p>
        <hr style="border: none; border-top: 1px solid #ddd; margin: 24px 0;" />
        <p style="color: #aaa; font-size: 12px;">
          If the button above doesn't work, copy and paste this URL into your browser:<br/>
          <a href="${resetLink}" style="color: #2e7d32; word-break: break-all;">${resetLink}</a>
        </p>
      </div>
    `,
    text: [
      'Reset your My Medicine password',
      '',
      'We received a request to reset your password.',
      'Open the link below to set a new password (valid for 1 hour):',
      '',
      resetLink,
      '',
      "If you didn't request this, ignore this email.",
    ].join('\n'),
  });
}

module.exports = { sendPasswordResetEmail };
