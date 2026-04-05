const { config } = require('../config/env');

function isWhatsAppConfigured() {
  return Boolean(
    config.whatsappAccessToken &&
      config.whatsappPhoneNumberId &&
      config.whatsappTemplateName,
  );
}

async function sendAuthenticationCode({ phoneNumber, code }) {
  if (!phoneNumber || !code) {
    throw new Error('phoneNumber and code are required');
  }

  if (!isWhatsAppConfigured()) {
    throw new Error('WhatsApp Business API is not configured');
  }

  const response = await fetch(
    `https://graph.facebook.com/${config.whatsappGraphApiVersion}/${config.whatsappPhoneNumberId}/messages`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.whatsappAccessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to: phoneNumber,
        type: 'template',
        template: {
          name: config.whatsappTemplateName,
          language: {
            code: config.whatsappTemplateLanguageCode,
          },
          components: [
            {
              type: 'body',
              parameters: [
                {
                  type: 'text',
                  text: code,
                },
              ],
            },
          ],
        },
      }),
    },
  );

  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    const providerMessage = payload?.error?.message || 'WhatsApp send failed';
    throw new Error(providerMessage);
  }

  const providerMessageId = payload?.messages?.[0]?.id || null;

  return {
    delivered: true,
    providerMessageId,
    payload,
  };
}

module.exports = {
  isWhatsAppConfigured,
  sendAuthenticationCode,
};
