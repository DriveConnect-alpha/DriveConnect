/**
 * Funções para enviar mídia (imagens, documentos, etc) via WhatsApp
 * Integração com agent para enviar fotos de veículos
 */

function mustGetEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Environment variable ${name} is required`);
  }
  return value;
}

/**
 * Envia uma imagem via WhatsApp usando uma URL pública
 * @param to Número de telefone do destinatário (com código de país)
 * @param imageUrl URL pública da imagem
 * @param caption Legenda opcional
 * @returns ID da mensagem ou null se falhar
 */
export async function sendImageByUrl(
  to: string,
  imageUrl: string,
  caption?: string,
): Promise<string | null> {
  const graphApiVersion = process.env.WHATSAPP_GRAPH_API_VERSION ?? process.env.GRAPH_API_VERSION ?? 'v19.0';
  const accessToken = process.env.WHATSAPP_ACCESS_TOKEN ?? process.env.ACCESS_TOKEN ?? mustGetEnv('WHATSAPP_ACCESS_TOKEN');
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID ?? process.env.PHONE_NUMBER_ID ?? mustGetEnv('WHATSAPP_PHONE_NUMBER_ID');

  const timeoutMs = Number.parseInt(process.env.WHATSAPP_TIMEOUT_MS || process.env.AXIOS_TIMEOUT_MS || '10000', 10);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const payload: any = {
      messaging_product: 'whatsapp',
      to,
      type: 'image',
      image: {
        link: imageUrl,
      },
    };

    if (caption) {
      payload.image.caption = caption;
    }

    const response = await fetch(
      `https://graph.facebook.com/${graphApiVersion}/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      },
    );

    clearTimeout(timeout);

    if (response.ok) {
      const data = (await response.json()) as { messages: { id: string }[] };
      const messageId = data?.messages?.[0]?.id || null;
      console.log(`[WhatsApp] Imagem enviada para ${to} | ID: ${messageId}`);
      return messageId;
    } else {
      const errorText = await response.text();
      console.error(`[WhatsApp] Erro ao enviar imagem: ${response.status} - ${errorText}`);
      return null;
    }
  } catch (err) {
    clearTimeout(timeout);
    console.error(`[WhatsApp] Erro ao enviar imagem:`, err);
    return null;
  }
}

/**
 * Envia múltiplas imagens em sequência
 * @param to Número do destinatário
 * @param imageUrls Array de URLs de imagens
 * @param delayMs Delay entre envios em ms (para não sobrecarregar API)
 */
export async function sendMultipleImages(
  to: string,
  imageUrls: string[],
  delayMs = 500,
): Promise<string[]> {
  const messageIds: string[] = [];

  for (const url of imageUrls) {
    const messageId = await sendImageByUrl(to, url);
    if (messageId) {
      messageIds.push(messageId);
    }
    // Delay para evitar rate limit
    await new Promise(resolve => setTimeout(resolve, delayMs));
  }

  return messageIds;
}

/**
 * Envia um documento/PDF via WhatsApp
 * @param to Número do destinatário
 * @param documentUrl URL pública do documento
 * @param filename Nome do arquivo a exibir
 * @param caption Legenda opcional
 */
export async function sendDocument(
  to: string,
  documentUrl: string,
  filename: string,
  caption?: string,
): Promise<string | null> {
  const graphApiVersion = process.env.WHATSAPP_GRAPH_API_VERSION ?? process.env.GRAPH_API_VERSION ?? 'v19.0';
  const accessToken = process.env.WHATSAPP_ACCESS_TOKEN ?? process.env.ACCESS_TOKEN ?? mustGetEnv('WHATSAPP_ACCESS_TOKEN');
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID ?? process.env.PHONE_NUMBER_ID ?? mustGetEnv('WHATSAPP_PHONE_NUMBER_ID');

  const timeoutMs = Number.parseInt(process.env.WHATSAPP_TIMEOUT_MS || process.env.AXIOS_TIMEOUT_MS || '10000', 10);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const payload: any = {
      messaging_product: 'whatsapp',
      to,
      type: 'document',
      document: {
        link: documentUrl,
        filename,
      },
    };

    if (caption) {
      payload.document.caption = caption;
    }

    const response = await fetch(
      `https://graph.facebook.com/${graphApiVersion}/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      },
    );

    clearTimeout(timeout);

    if (response.ok) {
      const data = (await response.json()) as { messages: { id: string }[] };
      const messageId = data?.messages?.[0]?.id || null;
      console.log(`[WhatsApp] Documento enviado para ${to} | ID: ${messageId}`);
      return messageId;
    } else {
      const errorText = await response.text();
      console.error(`[WhatsApp] Erro ao enviar documento: ${response.status} - ${errorText}`);
      return null;
    }
  } catch (err) {
    clearTimeout(timeout);
    console.error(`[WhatsApp] Erro ao enviar documento:`, err);
    return null;
  }
}

/**
 * Envia um vídeo via WhatsApp
 * @param to Número do destinatário
 * @param videoUrl URL pública do vídeo
 * @param caption Legenda opcional
 */
export async function sendVideo(
  to: string,
  videoUrl: string,
  caption?: string,
): Promise<string | null> {
  const graphApiVersion = process.env.WHATSAPP_GRAPH_API_VERSION ?? process.env.GRAPH_API_VERSION ?? 'v19.0';
  const accessToken = process.env.WHATSAPP_ACCESS_TOKEN ?? process.env.ACCESS_TOKEN ?? mustGetEnv('WHATSAPP_ACCESS_TOKEN');
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID ?? process.env.PHONE_NUMBER_ID ?? mustGetEnv('WHATSAPP_PHONE_NUMBER_ID');

  const timeoutMs = Number.parseInt(process.env.WHATSAPP_TIMEOUT_MS || process.env.AXIOS_TIMEOUT_MS || '10000', 10);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const payload: any = {
      messaging_product: 'whatsapp',
      to,
      type: 'video',
      video: {
        link: videoUrl,
      },
    };

    if (caption) {
      payload.video.caption = caption;
    }

    const response = await fetch(
      `https://graph.facebook.com/${graphApiVersion}/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      },
    );

    clearTimeout(timeout);

    if (response.ok) {
      const data = (await response.json()) as { messages: { id: string }[] };
      const messageId = data?.messages?.[0]?.id || null;
      console.log(`[WhatsApp] Vídeo enviado para ${to} | ID: ${messageId}`);
      return messageId;
    } else {
      const errorText = await response.text();
      console.error(`[WhatsApp] Erro ao enviar vídeo: ${response.status} - ${errorText}`);
      return null;
    }
  } catch (err) {
    clearTimeout(timeout);
    console.error(`[WhatsApp] Erro ao enviar vídeo:`, err);
    return null;
  }
}
