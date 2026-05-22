/**
 * Funções para enviar mídia (imagens, documentos, etc) via WhatsApp
 * Integração com agent para enviar fotos de veículos
 */

import fs from 'fs';
import path from 'path';

function mustGetEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Environment variable ${name} is required`);
  }
  return value;
}

function getMimeTypeFromFilename(filename: string): string {
  const ext = path.extname(filename).toLowerCase();
  if (ext === '.png') return 'image/png';
  if (ext === '.webp') return 'image/webp';
  if (ext === '.gif') return 'image/gif';
  if (ext === '.bmp') return 'image/bmp';
  return 'image/jpeg';
}

function deriveLocalStoragePath(imageUrl: string): string | null {
  try {
    const parsed = new URL(imageUrl);
    const pathname = parsed.pathname || '';
    const storagePrefix = '/storage/carros/';
    const uploadsPrefix = '/uploads/carros/';

    let filename = '';
    if (pathname.startsWith(storagePrefix)) {
      filename = pathname.slice(storagePrefix.length);
    } else if (pathname.startsWith(uploadsPrefix)) {
      filename = pathname.slice(uploadsPrefix.length);
    }

    if (!filename) return null;
    return path.join(process.cwd(), 'uploads', 'carros', decodeURIComponent(filename));
  } catch {
    return null;
  }
}

async function sendImageFromLocalFile(
  to: string,
  localFilePath: string,
  caption?: string,
): Promise<string | null> {
  const graphApiVersion = process.env.WHATSAPP_GRAPH_API_VERSION ?? process.env.GRAPH_API_VERSION ?? 'v19.0';
  const accessToken = process.env.WHATSAPP_ACCESS_TOKEN ?? process.env.ACCESS_TOKEN ?? mustGetEnv('WHATSAPP_ACCESS_TOKEN');
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID ?? process.env.PHONE_NUMBER_ID ?? mustGetEnv('WHATSAPP_PHONE_NUMBER_ID');

  if (!fs.existsSync(localFilePath)) {
    return null;
  }

  const fileBuffer = fs.readFileSync(localFilePath);
  const mimeType = getMimeTypeFromFilename(localFilePath);
  const fileName = path.basename(localFilePath);

  try {
    const form = new FormData();
    form.append('messaging_product', 'whatsapp');
    form.append('type', 'image');
    form.append('file', new Blob([fileBuffer], { type: mimeType }), fileName);

    const uploadResponse = await fetch(
      `https://graph.facebook.com/${graphApiVersion}/${phoneNumberId}/media`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
        body: form,
      },
    );

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text();
      console.error(`[WhatsApp] Erro ao enviar mídia local: ${uploadResponse.status} - ${errorText}`);
      return null;
    }

    const uploadData = (await uploadResponse.json()) as { id?: string };
    const mediaId = uploadData?.id;
    if (!mediaId) return null;

    const payload: any = {
      messaging_product: 'whatsapp',
      to,
      type: 'image',
      image: {
        id: mediaId,
      },
    };

    if (caption) {
      payload.image.caption = caption;
    }

    const sendResponse = await fetch(
      `https://graph.facebook.com/${graphApiVersion}/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      },
    );

    if (!sendResponse.ok) {
      const errorText = await sendResponse.text();
      console.error(`[WhatsApp] Erro ao disparar imagem por mídia: ${sendResponse.status} - ${errorText}`);
      return null;
    }

    const responseData = (await sendResponse.json()) as { messages?: { id: string }[] };
    return responseData?.messages?.[0]?.id || null;
  } catch (err) {
    console.error('[WhatsApp] Erro ao enviar imagem por mídia local:', err);
    return null;
  }
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
      const localPath = deriveLocalStoragePath(imageUrl);
      if (localPath) {
        const fallbackId = await sendImageFromLocalFile(to, localPath, caption);
        if (fallbackId) {
          console.log(`[WhatsApp] Imagem enviada via mídia local para ${to} | ID: ${fallbackId}`);
          return fallbackId;
        }
      }
      return null;
    }
  } catch (err) {
    clearTimeout(timeout);
    console.error(`[WhatsApp] Erro ao enviar imagem:`, err);
    const localPath = deriveLocalStoragePath(imageUrl);
    if (localPath) {
      const fallbackId = await sendImageFromLocalFile(to, localPath, caption);
      if (fallbackId) {
        console.log(`[WhatsApp] Imagem enviada via mídia local para ${to} | ID: ${fallbackId}`);
        return fallbackId;
      }
    }
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
