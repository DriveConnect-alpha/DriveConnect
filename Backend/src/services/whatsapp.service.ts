// ──────────────────────────────────────────────
// Serviço para integrar com WhatsApp Cloud API
// ──────────────────────────────────────────────

import 'dotenv/config';
import { answerWhatsAppMessage } from '../ai/rag.js';
import { query } from '../db/index.js';
import {
  buscarVeiculoDisponivelPorFilial,
  calcularValorTotal,
  criarReservaPendente,
} from './reserva.service.js';
import {
  ensureConversation,
  getConversationHistory,
  getWhatsappReserva,
  linkReservaToConversation,
  markWhatsappReservaNotified,
  storeMessage,
  updateMessageStatus,
} from './whatsappStorage.service.js';
import { criarCliente } from './usuario.service.js';
import crypto from 'crypto';

type WhatsAppTextMessage = {
  from: string;
  id: string;
  timestamp?: string;
  type?: string;
  text?: { body?: string };
};

type WebhookPayload = {
  entry?: Array<{
    changes?: Array<{
      value?: {
        messages?: WhatsAppTextMessage[];
        statuses?: unknown[];
      };
    }>;
  }>;
};

function mustGetEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

const DEDUPE_TTL_MS = Number.parseInt(process.env.WHATSAPP_DEDUPE_TTL_MS || process.env.DEDUPE_TTL_MS || '600000', 10);
const seenMessageIds = new Map<string, number>();

function hasSeenMessage(messageId: string | undefined): boolean {
  if (!messageId) return false;
  const now = Date.now();
  const seenAt = seenMessageIds.get(messageId);
  if (seenAt && now - seenAt < DEDUPE_TTL_MS) return true;
  seenMessageIds.set(messageId, now);
  return false;
}

function cleanupSeen(): void {
  const now = Date.now();
  for (const [key, value] of seenMessageIds.entries()) {
    if (now - value >= DEDUPE_TTL_MS) seenMessageIds.delete(key);
  }
}

setInterval(cleanupSeen, Math.max(30_000, Math.floor(DEDUPE_TTL_MS / 2))).unref();

type Cached<T> = { value: T; expiresAt: number };
const cache = new Map<string, Cached<any>>();

type HistoryMessage = { role: 'user' | 'assistant'; content: string };

function setCache<T>(key: string, value: T, ttlMs: number): void {
  cache.set(key, { value, expiresAt: Date.now() + ttlMs });
}

function getCache<T>(key: string): T | null {
  const item = cache.get(key);
  if (!item) return null;
  if (Date.now() > item.expiresAt) {
    cache.delete(key);
    return null;
  }
  return item.value as T;
}

/**
 * Função para enviar uma mensagem via WhatsApp
 * @param to Número de telefone do destinatário
 * @param text Texto da mensagem a ser enviada
 */
export async function sendMessage(to: string, text: string): Promise<string | null> {
  const graphApiVersion = process.env.WHATSAPP_GRAPH_API_VERSION ?? process.env.GRAPH_API_VERSION ?? 'v19.0';
  const accessToken = process.env.WHATSAPP_ACCESS_TOKEN ?? process.env.ACCESS_TOKEN ?? mustGetEnv('WHATSAPP_ACCESS_TOKEN');
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID ?? process.env.PHONE_NUMBER_ID ?? mustGetEnv('WHATSAPP_PHONE_NUMBER_ID');

  const timeoutMs = Number.parseInt(process.env.WHATSAPP_TIMEOUT_MS || process.env.AXIOS_TIMEOUT_MS || '10000', 10);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(
      `https://graph.facebook.com/${graphApiVersion}/${phoneNumberId}/messages`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messaging_product: 'whatsapp',
          to,
          type: 'text',
          text: { body: text },
        }),
        signal: controller.signal,
      },
    );

    if (!response.ok) {
      const body = await response.text().catch(() => '');
      throw new Error(`Graph API error: HTTP ${response.status} ${body}`);
    }

    const json = await response.json().catch(() => ({}));
    const messageId = Array.isArray(json?.messages) ? json.messages[0]?.id : null;
    return messageId ?? null;
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Função para processar a chegada de um webhook (mensagens recebidas, atualizações de status)
 * @param payload Dados em JSON recebidos pelo Webhook
 */
export async function processIncomingMessage(payload: any): Promise<void> {
  const typed = payload as WebhookPayload;

  const entry = typed.entry?.[0];
  const changes = entry?.changes?.[0];
  const value = changes?.value;
  const message = value?.messages?.[0];
  const statuses = Array.isArray(value?.statuses)
    ? (value?.statuses as Array<{ id?: string; status?: string }> )
    : [];

  if (statuses.length > 0) {
    for (const status of statuses) {
      const statusId = status?.id;
      const statusValue = status?.status;
      if (statusId && statusValue) {
        await updateMessageStatus(statusId, statusValue);
      }
    }
  }

  if (!message) return;
  if (hasSeenMessage(message.id)) return;

  const from = message.from;
  const text = message.text?.body ?? '';

  const logBody = (process.env.WHATSAPP_LOG_MESSAGE_BODY ?? process.env.LOG_MESSAGE_BODY ?? '0') === '1';
  const logPayload: Record<string, unknown> = { id: message.id, from };
  if (logBody) logPayload.body = text;
  console.log('[WhatsApp Service] Mensagem recebida:', JSON.stringify(logPayload));

  const conversation = await ensureConversation(from);
  if (!conversation?.id) {
    console.error('[WhatsApp Service] Não foi possível abrir conversa para', from);
    return;
  }

  await storeMessage({
    conversationId: conversation.id,
    direction: 'IN',
    waMessageId: message.id,
    text,
    rawPayload: message,
    status: 'received',
  });

  if (!text) {
    const fallback = 'Mensagem de mídia recebida, consigo processar apenas texto no momento.';
    const fallbackMessageId = await sendMessage(from, fallback);
    await storeMessage({
      conversationId: conversation.id,
      direction: 'OUT',
      waMessageId: fallbackMessageId,
      text: fallback,
      status: 'sent',
    });
    return;
  }

  const history = await getConversationHistory(conversation.id, Number.parseInt(process.env.WHATSAPP_HISTORY_LIMIT || '12', 10));

  // Verificar se há intenção de reserva e cliente não cadastrado
  const reservationCheck = await tryHandleReservationIntent({
    messageText: text,
    phone: from,
    conversationId: conversation.id,
  });

  if (reservationCheck?.handled) {
    const replyMessageId = await sendMessage(from, reservationCheck.replyText);
    await storeMessage({
      conversationId: conversation.id,
      direction: 'OUT',
      waMessageId: replyMessageId,
      text: reservationCheck.replyText,
      status: 'sent',
    });
    return;
  }

  const paymentResult = await tryHandlePaymentIntent({
    messageText: text,
    phone: from,
    conversationId: conversation.id,
    history,
  });

  if (paymentResult?.handled) {
    const replyMessageId = await sendMessage(from, paymentResult.replyText);
    await storeMessage({
      conversationId: conversation.id,
      direction: 'OUT',
      waMessageId: replyMessageId,
      text: paymentResult.replyText,
      status: 'sent',
    });
    return;
  }

  const quickReplyMsRaw = process.env.WHATSAPP_QUICK_REPLY_MS ?? '0';
  const quickReplyMs = Number.parseInt(quickReplyMsRaw, 10);
  const quickReplyText = (process.env.WHATSAPP_QUICK_REPLY_TEXT || '').trim();

  let placeholderTimer: NodeJS.Timeout | null = null;
  if (Number.isFinite(quickReplyMs) && quickReplyMs > 0 && quickReplyText) {
    const safeQuickReplyMs = quickReplyMs >= 200 ? quickReplyMs : 1500;
    placeholderTimer = setTimeout(() => {
      void sendMessage(from, quickReplyText).catch((err) => {
        console.error('[WhatsApp Service] Erro enviando quick reply:', err);
      });
    }, safeQuickReplyMs);
    placeholderTimer.unref();
  }

  try {
    const reply = sanitizeAiPaymentReply(await answerWhatsAppMessage(text, { history }));
    if (placeholderTimer) clearTimeout(placeholderTimer);

    const replyMessageId = await sendMessage(from, reply);
    await storeMessage({
      conversationId: conversation.id,
      direction: 'OUT',
      waMessageId: replyMessageId,
      text: reply,
      status: 'sent',
    });
  } catch (error) {
    if (placeholderTimer) clearTimeout(placeholderTimer);
    console.error('[WhatsApp Service] Erro gerando resposta da IA:', error);
    const fallback = 'Desculpe, não consegui acessar a base de conhecimento agora. Pode tentar novamente em instantes?';
    const fallbackMessageId = await sendMessage(from, fallback);
    await storeMessage({
      conversationId: conversation.id,
      direction: 'OUT',
      waMessageId: fallbackMessageId,
      text: fallback,
      status: 'sent',
      error: String((error as Error)?.message || error),
    });
  }
}

function extractDateRange(messageText: string): { startDate: string | null; endDate: string | null } {
  const matches = (messageText || '').match(/\b(\d{1,2}\/\d{1,2}\/20\d{2}|20\d{2}-\d{2}-\d{2})\b/g);
  if (!matches || matches.length === 0) return { startDate: null, endDate: null };
  const startDate = parseDateToIso(matches[0]);
  const endDate = parseDateToIso(matches[1] || matches[0]);
  return { startDate, endDate };
}

function parseDateToIso(text: string | null): string | null {
  if (!text) return null;
  const t = text.trim();

  const iso = t.match(/\b(20\d{2})-(\d{2})-(\d{2})\b/);
  if (iso) return `${iso[1]}-${iso[2]}-${iso[3]}`;

  const br = t.match(/\b(\d{1,2})\/(\d{1,2})\/(20\d{2})\b/);
  if (br) {
    const [, ddRaw, mmRaw, yyyy] = br;
    if (!ddRaw || !mmRaw || !yyyy) return null;
    const dd = ddRaw.padStart(2, '0');
    const mm = mmRaw.padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  return null;
}

function normalizePhone(phone: string): string {
  return (phone || '').replace(/\D/g, '');
}

/**
 * Gera uma senha aleatória segura
 */
function generateSecurePassword(): string {
  const length = 12;
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';

  // Garantir pelo menos um de cada tipo
  password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 26)]; // maiúscula
  password += 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)]; // minúscula
  password += '0123456789'[Math.floor(Math.random() * 10)]; // número
  password += '!@#$%^&*'[Math.floor(Math.random() * 8)]; // especial

  // Preencher o resto aleatoriamente
  for (let i = password.length; i < length; i++) {
    password += chars[Math.floor(Math.random() * chars.length)];
  }

  // Embaralhar a senha
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

/**
 * Valida formato de email
 */
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Valida formato de CPF (apenas formato, não verifica se é real)
 */
function isValidCpfFormat(cpf: string): boolean {
  const cleanCpf = cpf.replace(/\D/g, '');
  return cleanCpf.length === 11 && /^\d{11}$/.test(cleanCpf);
}

/**
 * Extrai CPF e email de uma mensagem de texto
 */
function extractCpfAndEmail(text: string): { cpf: string | null; email: string | null } {
  const t = text.trim();

  // Extrair CPF - vários formatos possíveis
  const cpfPatterns = [
    /\b\d{3}\.\d{3}\.\d{3}-\d{2}\b/, // 123.456.789-01
    /\b\d{11}\b/, // 12345678901
    /\b\d{3}\d{3}\d{3}\d{2}\b/, // 12345678901 sem pontuação
  ];

  let cpf: string | null = null;
  for (const pattern of cpfPatterns) {
    const match = t.match(pattern);
    if (match) {
      cpf = match[0].replace(/\D/g, ''); // normalizar para apenas dígitos
      break;
    }
  }

  // Extrair email
  const emailMatch = t.match(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/i);
  const email = emailMatch ? emailMatch[0] : null;

  return { cpf, email };
}

function looksLikeCardDataRequest(text: string): boolean {
  const t = (text || '').toLowerCase();
  if (!t) return false;
  const patterns = [
    'cartão',
    'cartao',
    'número do cartão',
    'numero do cartao',
    'número do cartao',
    'validade',
    'cvv',
    'código de segurança',
    'codigo de seguranca',
    'titular do cartão',
    'titular do cartao',
    'dados do seu cartão',
    'dados do seu cartao',
  ];
  return patterns.some((p) => t.includes(p));
}

function sanitizeAiPaymentReply(text: string): string {
  if (!looksLikeCardDataRequest(text)) return text;
  const lower = text.toLowerCase();
  const hasLink = lower.includes('link de pagamento') || lower.includes('checkout');
  if (hasLink) return text;
  return 'Para finalizar, eu envio um link de pagamento seguro. Me informe o modelo do carro, a unidade de retirada e as datas (retirada e devolução).';
}

function isPaymentIntent(text: string): boolean {
  const t = (text || '').toLowerCase();
  const intentWords = ['pagar', 'pagamento', 'link', 'checkout', 'finalizar', 'fechar'];
  return intentWords.some((w) => t.includes(w));
}

function isReservationIntent(text: string): boolean {
  const t = (text || '').toLowerCase();
  const intentWords = ['alugar', 'aluguel', 'locar', 'locação', 'reserva', 'reservar', 'quero', 'gostaria', 'interessado'];
  const carWords = ['carro', 'veículo', 'veiculo', 'automóvel', 'automovel'];
  return intentWords.some((w) => t.includes(w)) && carWords.some((c) => t.includes(c));
}

function isConfirmation(text: string): boolean {
  const t = (text || '').trim().toLowerCase();
  if (!t) return false;
  const confirmations = [
    'sim',
    'ok',
    'claro',
    'confirmo',
    'quero',
    'pode',
    'isso',
    'perfeito',
    'segue',
    'pode sim',
    'pode prosseguir',
  ];
  return confirmations.some((c) => t === c || t.startsWith(`${c} `));
}

function historyHasReservationContext(history: HistoryMessage[] | undefined): boolean {
  if (!history || history.length === 0) return false;
  const combined = history.map((m) => m.content).join(' ').toLowerCase();
  const hasDate = /\b(\d{1,2}\/\d{1,2}\/20\d{2}|20\d{2}-\d{2}-\d{2})\b/.test(combined);
  const hasKeywords = ['modelo', 'unidade', 'retirada', 'devolução', 'devolucao', 'reserva'].some((k) => combined.includes(k));
  return hasDate || hasKeywords;
}

function buildPaymentContextText(messageText: string, history: HistoryMessage[] | undefined): string {
  if (!history || history.length === 0) return messageText;
  const recentUser = history.filter((m) => m.role === 'user').slice(-3).map((m) => m.content);
  const combined = [...recentUser, messageText].filter(Boolean).join(' ');
  return combined.trim() || messageText;
}

async function detectModelo(messageText: string): Promise<{ id: number; descricao: string } | null> {
  const t = (messageText || '').toLowerCase();
  const cached = getCache<Array<{ id: number; nome: string; marca: string }>>('modelos');
  const rows = cached ?? (await query('SELECT id, nome, marca FROM modelo ORDER BY nome')).rows;
  if (!cached) setCache('modelos', rows, 5 * 60_000);
  for (const row of rows) {
    const nome = String(row.nome || '').trim();
    const marca = String(row.marca || '').trim();
    if (!nome) continue;
    const nomeLower = nome.toLowerCase();
    const marcaLower = marca.toLowerCase();
    const combos = [
      nomeLower,
      marcaLower ? `${marcaLower} ${nomeLower}` : '',
      marcaLower ? `${nomeLower} ${marcaLower}` : '',
    ].filter(Boolean);
    if (combos.some((c) => t.includes(c))) {
      return { id: Number(row.id), descricao: `${marca} ${nome}`.trim() };
    }
  }
  return null;
}

async function detectFilialId(messageText: string): Promise<string | null> {
  const t = (messageText || '').toLowerCase();
  const cached = getCache<Array<{ id: string; nome: string; cidade: string; uf: string }>>('filiais');
  const rows = cached ?? (await query(
    `SELECT id, nome, cidade, uf FROM filial WHERE deletado_em IS NULL AND ativo = TRUE ORDER BY nome`,
  )).rows;
  if (!cached) setCache('filiais', rows, 5 * 60_000);

  if (rows.length === 1) return String(rows[0].id);

  for (const row of rows) {
    const nome = String(row.nome || '').toLowerCase();
    const cidade = String(row.cidade || '').toLowerCase();
    const uf = String(row.uf || '').toLowerCase();
    if ((nome && t.includes(nome)) || (cidade && t.includes(cidade)) || (uf && t.includes(uf))) {
      return String(row.id);
    }
  }
  return null;
}

async function findClienteByPhone(phone: string): Promise<{ id: string; nome: string; email: string; telefone?: string | null } | null> {
  const normalized = normalizePhone(phone);
  if (!normalized) return null;
  try {
    const result = await query(
      `SELECT c.id, c.nome_completo, u.email, c.telefone
       FROM cliente c
       JOIN usuario u ON u.id = c.usuario_id
       WHERE regexp_replace(c.telefone, '\\D', '', 'g') = $1
       LIMIT 1`,
      [normalized],
    );
    const row = result.rows[0];
    if (!row) return null;
    return {
      id: row.id,
      nome: row.nome_completo,
      email: row.email,
      telefone: row.telefone ?? null,
    };
  } catch (err) {
    console.error('[WhatsApp] Erro buscando cliente por telefone:', err);
    return null;
  }
}

async function tryHandleReservationIntent(params: {
  messageText: string;
  phone: string;
  conversationId: string;
}): Promise<{ handled: boolean; replyText: string }> {
  const { messageText, phone } = params;

  // Verificar se há intenção de reserva/aluguel
  if (!isReservationIntent(messageText)) {
    return { handled: false, replyText: '' };
  }

  // Verificar se o cliente já está cadastrado
  const cliente = await findClienteByPhone(phone);
  if (cliente) {
    // Cliente já cadastrado, deixar o fluxo normal continuar
    return { handled: false, replyText: '' };
  }

  // Cliente não cadastrado - verificar se forneceu CPF e email na mensagem
  const { cpf, email } = extractCpfAndEmail(messageText);

  if (cpf && email && isValidCpfFormat(cpf) && isValidEmail(email)) {
    // Tentar cadastrar o cliente automaticamente
    try {
      const nomeCliente = `Cliente WhatsApp ${phone.slice(-4)}`; // Nome temporário baseado no telefone
      const senhaGerada = generateSecurePassword();

      const resultadoCadastro = await criarCliente({
        email,
        senha: senhaGerada,
        nomeCompleto: nomeCliente,
        cpf,
        telefone: phone,
      });

      console.log(`[WhatsApp] Cliente cadastrado automaticamente via reserva: ${resultadoCadastro.usuarioId}`);

      // Enviar mensagem com as credenciais
      const mensagemCredenciais = `✅ Cadastro realizado com sucesso!\n\n` +
        `📧 Email: ${email}\n` +
        `🔑 Senha temporária: ${senhaGerada}\n\n` +
        `⚠️ Guarde essas informações! Você pode alterar a senha no app ou site.\n\n` +
        `Agora posso te ajudar com sua reserva. Me informe o modelo do carro, unidade e datas (retirada e devolução).`;

      return {
        handled: true,
        replyText: mensagemCredenciais,
      };
     } catch (error) {
       console.error('[WhatsApp] Erro no cadastro automático via reserva:', error);
       return {
         handled: true,
         replyText: `Olá! Vejo que você quer alugar um carro, mas preciso do seu cadastro primeiro. Me informe seu CPF e e‑mail para fazer o cadastro automático.`,
       };
     }
  } else {
    // Cliente não cadastrado e não forneceu dados suficientes
    return {
      handled: true,
      replyText: `Olá! Vejo que você quer alugar um carro, mas preciso do seu cadastro primeiro. Me informe seu CPF e e‑mail para fazer o cadastro automático.`,
    };
  }
}

async function tryHandlePaymentIntent(params: {
  messageText: string;
  phone: string;
  conversationId: string;
  history?: HistoryMessage[];
}): Promise<{ handled: boolean; replyText: string }> {
  const { messageText, phone, conversationId, history } = params;

  const shouldHandle = isPaymentIntent(messageText) || (isConfirmation(messageText) && historyHasReservationContext(history));
  if (!shouldHandle) {
    return { handled: false, replyText: '' };
  }

  const intentText = buildPaymentContextText(messageText, history);
  const { startDate, endDate } = extractDateRange(intentText);
  const modelo = await detectModelo(intentText);
  const filialId = await detectFilialId(intentText);

  if (startDate && endDate) {
    const inicio = new Date(startDate);
    const fim = new Date(endDate);
    if (!(inicio instanceof Date) || !(fim instanceof Date) || Number.isNaN(inicio.getTime()) || Number.isNaN(fim.getTime())) {
      return {
        handled: true,
        replyText: 'As datas informadas estão inválidas. Pode enviar no formato DD/MM/AAAA?',
      };
    }
    if (fim.getTime() <= inicio.getTime()) {
      return {
        handled: true,
        replyText: 'A data de devolução precisa ser depois da retirada. Pode corrigir, por favor?',
      };
    }
  }

  if (!startDate || !endDate || !modelo || !filialId) {
    return {
      handled: true,
      replyText: 'Consigo gerar seu link de pagamento. Me envie: modelo do carro, unidade de retirada e datas (retirada e devolução).',
    };
  }

  let cliente = await findClienteByPhone(phone);
  if (!cliente) {
    // Verificar se a mensagem contém CPF e email para cadastro automático
    const { cpf, email } = extractCpfAndEmail(messageText);

    if (cpf && email && isValidCpfFormat(cpf) && isValidEmail(email)) {
      // Tentar cadastrar o cliente automaticamente
      try {
        const nomeCliente = `Cliente WhatsApp ${phone.slice(-4)}`; // Nome temporário baseado no telefone
        const senhaGerada = generateSecurePassword();

        const resultadoCadastro = await criarCliente({
          email,
          senha: senhaGerada,
          nomeCompleto: nomeCliente,
          cpf,
          telefone: phone,
        });

        console.log(`[WhatsApp] Cliente cadastrado automaticamente: ${resultadoCadastro.usuarioId}`);

        // Buscar o cliente recém-criado
        cliente = await findClienteByPhone(phone);

        if (cliente) {
          // Enviar mensagem com as credenciais
          const mensagemCredenciais = `✅ Cadastro realizado com sucesso!\n\n` +
            `📧 Email: ${email}\n` +
            `🔑 Senha temporária: ${senhaGerada}\n\n` +
            `⚠️ Guarde essas informações! Você pode alterar a senha no app ou site.\n\n` +
            `Agora posso gerar seu link de pagamento.`;

          // Enviar mensagem separada com credenciais primeiro
          await sendMessage(phone, mensagemCredenciais);

          // Continuar com o fluxo normal
        } else {
          throw new Error('Falha ao buscar cliente recém-cadastrado');
        }
       } catch (error) {
         console.error('[WhatsApp] Erro no cadastro automático:', error);
         return {
           handled: true,
           replyText: `Não consegui fazer seu cadastro automático. Verifique se o CPF e email estão corretos.`,
         };
       }
    } else {
      return {
        handled: true,
        replyText: `Para gerar o link, preciso do seu cadastro. Se preferir, me informe seu CPF e e‑mail para localizar sua conta.`,
      };
    }
  }

  const inicio = new Date(startDate);
  const fim = new Date(endDate);
  const veiculoId = await buscarVeiculoDisponivelPorFilial(modelo.id, filialId, inicio, fim);

  if (!veiculoId) {
    return {
      handled: true,
      replyText: 'Não encontrei disponibilidade para esse modelo e período. Quer que eu verifique outra categoria ou datas próximas?',
    };
  }

  const valorAluguel = await calcularValorTotal(modelo.id, filialId, inicio, fim);
  const reserva = await criarReservaPendente({
    clienteId: cliente.id,
    veiculoId,
    filialRetiradaId: filialId,
    filialDevolucaoId: filialId,
    dataInicio: inicio,
    dataFim: fim,
    valorAluguel,
    nomeCliente: cliente.nome,
    emailCliente: cliente.email,
    telefoneCliente: cliente.telefone ?? phone,
    descricaoModelo: modelo.descricao,
    origem: 'WHATSAPP',
  });

  await linkReservaToConversation({
    reservaId: reserva.reservaId,
    phone,
    conversationId,
  });

  return {
    handled: true,
    replyText: `Perfeito! Aqui está seu link de pagamento: ${reserva.linkPagamento}\nAssim que o pagamento for confirmado, eu te aviso por aqui.`,
  };
}

export async function notifyPaymentConfirmed(reservaId: string): Promise<void> {
  if (!reservaId) return;

  const vinculo = await getWhatsappReserva(reservaId);
  if (!vinculo || vinculo.notifiedAt) return;

  const dados = await query(
    `SELECT r.id, r.data_inicio, r.data_fim, f.nome AS filial_nome, f.cidade, f.uf,
            m.nome AS modelo, m.marca
     FROM reserva r
     JOIN veiculo v ON v.id = r.veiculo_id
     JOIN modelo m ON m.id = v.modelo_id
     JOIN filial f ON f.id = r.filial_retirada_id
     WHERE r.id = $1`,
    [reservaId],
  );

  const row = dados.rows[0];
  const inicio = row?.data_inicio ? new Date(row.data_inicio).toLocaleDateString('pt-BR') : null;
  const fim = row?.data_fim ? new Date(row.data_fim).toLocaleDateString('pt-BR') : null;
  const modelo = row?.modelo ? `${row.modelo}${row.marca ? ` ${row.marca}` : ''}` : 'seu veículo';
  const local = [row?.filial_nome, row?.cidade, row?.uf].filter(Boolean).join(' / ');

  const texto = `Pagamento confirmado! Sua reserva está confirmada para ${inicio} até ${fim}.` +
    `${modelo ? ` Modelo: ${modelo}.` : ''}` +
    `${local ? ` Unidade: ${local}.` : ''}` +
    ' Obrigado! Se precisar ajustar algo, me avise.';

  const conversation = vinculo.conversationId
    ? { id: vinculo.conversationId }
    : await ensureConversation(vinculo.phone);

  if (!conversation?.id) return;

  const messageId = await sendMessage(vinculo.phone, texto);
  await storeMessage({
    conversationId: conversation.id,
    direction: 'OUT',
    waMessageId: messageId,
    text: texto,
    status: 'sent',
  });

  await markWhatsappReservaNotified(reservaId);
}
