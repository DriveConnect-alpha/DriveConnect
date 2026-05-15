import { IncomingMessage, ServerResponse } from 'http';
import * as crypto from 'crypto';
import { processIncomingMessage } from '../services/whatsapp.service.js';
import { listConversationMessages, listConversations } from '../services/whatsappStorage.service.js';
import { checkRole } from '../utils/auth.js';

type CorpoLido = { raw: Buffer; json: Record<string, any> };

function parseBooleanEnv(value: string | undefined, fallback: boolean): boolean {
  if (value === undefined) return fallback;
  return value === '1' || value.toLowerCase() === 'true' || value.toLowerCase() === 'yes';
}

function safeTimingEqualHex(aHex: string, bHex: string): boolean {
  try {
    const a = Buffer.from(aHex, 'hex');
    const b = Buffer.from(bHex, 'hex');
    if (a.length !== b.length) return false;
    return crypto.timingSafeEqual(a, b);
  } catch {
    return false;
  }
}

function verifyMetaSignature(rawBody: Buffer, signatureHeader: string, appSecret: string): boolean {
  const [algo, signatureHex] = (signatureHeader || '').split('=');
  if (algo !== 'sha256' || !signatureHex) return false;

  const expectedHex = crypto
    .createHmac('sha256', appSecret)
    .update(rawBody)
    .digest('hex');

  return safeTimingEqualHex(signatureHex, expectedHex);
}

function lerCorpo(req: IncomingMessage): Promise<CorpoLido> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on('data', (chunk) => chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)));
    req.on('end', () => {
      const raw = chunks.length ? Buffer.concat(chunks) : Buffer.from('{}');
      try {
        const rawText = raw.toString('utf8');
        resolve({ raw, json: JSON.parse(rawText) });
      }
      catch { reject(new Error('JSON inválido no corpo da requisição.')); }
    });
    req.on('error', reject);
  });
}

function isJsonContentType(req: IncomingMessage): boolean {
  const contentType = String(req.headers['content-type'] ?? '');
  return contentType.toLowerCase().includes('application/json');
}

type RateState = { startMs: number; count: number };
const rateLimitState = new Map<string, RateState>();

function isRateLimited(ip: string, windowMs: number, max: number): boolean {
  const now = Date.now();
  const current = rateLimitState.get(ip);
  if (!current || now - current.startMs >= windowMs) {
    rateLimitState.set(ip, { startMs: now, count: 1 });
    return false;
  }
  current.count += 1;
  return current.count > max;
}

function cleanupRateLimit(windowMs: number): void {
  const now = Date.now();
  for (const [ip, state] of rateLimitState.entries()) {
    if (now - state.startMs >= windowMs) rateLimitState.delete(ip);
  }
}

// ──────────────────────────────────────────────
// GET /whatsapp/webhook
// Verificação do webhook da Meta
// ──────────────────────────────────────────────
export async function verifyWebhook(req: IncomingMessage, res: ServerResponse) {
  const url = new URL(req.url ?? '', `http://${req.headers.host}`);

  const mode = url.searchParams.get('hub.mode');
  const token = url.searchParams.get('hub.verify_token');
  const challenge = url.searchParams.get('hub.challenge');

  const verifyToken =
    process.env.WHATSAPP_VERIFY_TOKEN ??
    process.env.VERIFY_TOKEN ??
    '';

  if (mode === 'subscribe' && token === verifyToken && challenge) {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end(challenge);
    return;
  }

  res.writeHead(403, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ erro: 'Webhook verification failed.' }));
}

// ──────────────────────────────────────────────
// POST /whatsapp/webhook
// Recebe mensagens e notificações do WhatsApp
// ──────────────────────────────────────────────
export async function receiveWebhook(req: IncomingMessage, res: ServerResponse) {
  if (!isJsonContentType(req)) {
    res.writeHead(415, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Content-Type deve ser application/json.' }));
    return;
  }

  const ip =
    String(req.headers['x-forwarded-for'] ?? '').split(',')[0]?.trim() ||
    (req.socket.remoteAddress ?? 'unknown');

  const rateWindowMs = Number.parseInt(process.env.WHATSAPP_RATE_LIMIT_WINDOW_MS || '60000', 10);
  const rateMax = Number.parseInt(process.env.WHATSAPP_RATE_LIMIT_MAX || '120', 10);

  if (Number.isFinite(rateWindowMs) && Number.isFinite(rateMax) && rateWindowMs > 0 && rateMax > 0) {
    cleanupRateLimit(rateWindowMs);
    if (isRateLimited(ip, rateWindowMs, rateMax)) {
      res.writeHead(429, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ erro: 'Rate limit excedido.' }));
      return;
    }
  }

  const appSecret = process.env.WHATSAPP_APP_SECRET ?? process.env.APP_SECRET;
  const requireSignature = parseBooleanEnv(
    process.env.WHATSAPP_REQUIRE_SIGNATURE ?? process.env.WEBHOOK_REQUIRE_SIGNATURE,
    process.env.NODE_ENV === 'production',
  );

  if (requireSignature && !appSecret) {
    // erro de configuração
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'APP_SECRET não configurado para validação de assinatura.' }));
    return;
  }

  let raw: Buffer;
  let json: Record<string, any>;
  try {
    ({ raw, json } = await lerCorpo(req));
  } catch {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'JSON inválido no corpo da requisição.' }));
    return;
  }

  if (requireSignature && appSecret) {
    const signatureHeader = String(req.headers['x-hub-signature-256'] ?? '');
    const ok = verifyMetaSignature(raw, signatureHeader, appSecret);
    if (!ok) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ erro: 'Assinatura inválida.' }));
      return;
    }
  } else if (requireSignature) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Assinatura requerida mas APP_SECRET ausente.' }));
    return;
  }

  // Resposta rápida para a Meta
  res.writeHead(200);
  res.end();

  // Processamento assíncrono (evita timeout do webhook)
  void processIncomingMessage(json).catch((err) => {
    console.error('[WhatsApp] Erro ao processar webhook:', err);
  });
}

function parsePositiveInt(value: string | null, fallback: number): number {
  const parsed = Number.parseInt(value ?? '', 10);
  if (!Number.isFinite(parsed) || parsed < 0) return fallback;
  return parsed;
}

// ──────────────────────────────────────────────
// GET /whatsapp/conversations
// Listagem administrativa de conversas
// ──────────────────────────────────────────────
export async function listAdminConversations(req: IncomingMessage, res: ServerResponse) {
  const currentUser = checkRole(req, res, ['ADMIN']);
  if (!currentUser) return;

  try {
    const url = new URL(req.url ?? '', `http://${req.headers.host}`);
    const limit = parsePositiveInt(url.searchParams.get('limit'), 30);
    const offset = parsePositiveInt(url.searchParams.get('offset'), 0);
    const phone = (url.searchParams.get('phone') ?? '').trim();

    const rows = await listConversations({
      limit,
      offset,
      phone: phone || undefined,
    });

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      data: rows,
      page: {
        limit,
        offset,
        count: rows.length,
      },
    }));
  } catch (error) {
    console.error('[WhatsApp] Erro ao listar conversas:', error);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Erro ao listar conversas do WhatsApp.' }));
  }
}

// ──────────────────────────────────────────────
// GET /whatsapp/conversations/:id/messages
// Mensagens de uma conversa (admin)
// ──────────────────────────────────────────────
export async function listAdminConversationMessages(req: IncomingMessage, res: ServerResponse, conversationId: string) {
  const currentUser = checkRole(req, res, ['ADMIN']);
  if (!currentUser) return;

  if (!conversationId) {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'conversationId é obrigatório.' }));
    return;
  }

  try {
    const url = new URL(req.url ?? '', `http://${req.headers.host}`);
    const limit = parsePositiveInt(url.searchParams.get('limit'), 100);
    const offset = parsePositiveInt(url.searchParams.get('offset'), 0);

    const rows = await listConversationMessages({
      conversationId,
      limit,
      offset,
    });

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      data: rows,
      page: {
        limit,
        offset,
        count: rows.length,
      },
    }));
  } catch (error) {
    console.error('[WhatsApp] Erro ao listar mensagens da conversa:', error);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Erro ao listar mensagens da conversa.' }));
  }
}
