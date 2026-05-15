import { query } from '../db/index.js';

export type WhatsappMessageDirection = 'IN' | 'OUT';

export type StoredMessage = {
  id: string;
  conversationId: string;
  direction: WhatsappMessageDirection;
  waMessageId?: string | null;
  text?: string | null;
  status: string;
  createdAt: Date;
};

export type WhatsappConversationSummary = {
  id: string;
  phone: string;
  status: string;
  lastMessageAt: Date | null;
  createdAt: Date;
  lastMessageText: string | null;
  lastMessageDirection: WhatsappMessageDirection | null;
  paused: boolean;
};

export async function ensureConversation(phone: string): Promise<{ id: string } | null> {
  if (!phone) return null;

  const existing = await query(
    'SELECT id FROM whatsapp_conversation WHERE phone = $1 LIMIT 1',
    [phone],
  );

  if (existing.rows[0]?.id) {
    await query(
      'UPDATE whatsapp_conversation SET last_message_at = NOW() WHERE id = $1',
      [existing.rows[0].id],
    );
    return { id: existing.rows[0].id };
  }

  const created = await query(
    'INSERT INTO whatsapp_conversation (phone, status) VALUES ($1, $2) RETURNING id',
    [phone, 'OPEN'],
  );

  return created.rows[0]?.id ? { id: created.rows[0].id } : null;
}

export async function storeMessage(params: {
  conversationId: string;
  direction: WhatsappMessageDirection;
  waMessageId?: string | null;
  text?: string | null;
  rawPayload?: unknown;
  status?: string;
  error?: string | null;
}): Promise<StoredMessage | null> {
  const {
    conversationId,
    direction,
    waMessageId,
    text,
    rawPayload,
    status = direction === 'IN' ? 'received' : 'sent',
    error,
  } = params;

  const result = await query(
    `INSERT INTO whatsapp_message (
      conversation_id, direction, wa_message_id, text, raw_payload, status, error
    ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id, conversation_id, direction, wa_message_id, text, status, created_at`,
    [
      conversationId,
      direction,
      waMessageId ?? null,
      text ?? null,
      rawPayload ? JSON.stringify(rawPayload) : null,
      status,
      error ?? null,
    ],
  );

  const row = result.rows[0];
  if (!row) return null;
  return {
    id: row.id,
    conversationId: row.conversation_id,
    direction: row.direction,
    waMessageId: row.wa_message_id,
    text: row.text,
    status: row.status,
    createdAt: row.created_at,
  };
}

export async function updateMessageStatus(waMessageId: string, status: string): Promise<void> {
  if (!waMessageId) return;
  await query(
    `UPDATE whatsapp_message
     SET status = $1
     WHERE wa_message_id = $2`,
    [status, waMessageId],
  );
}

export async function linkReservaToConversation(params: {
  reservaId: string;
  phone: string;
  conversationId?: string | null;
}): Promise<void> {
  const { reservaId, phone, conversationId } = params;
  if (!reservaId || !phone) return;

  await query(
    `INSERT INTO whatsapp_reserva (reserva_id, phone, conversation_id)
     VALUES ($1, $2, $3)
     ON CONFLICT (reserva_id)
     DO UPDATE SET phone = EXCLUDED.phone, conversation_id = EXCLUDED.conversation_id`,
    [reservaId, phone, conversationId ?? null],
  );
}

export async function getWhatsappReserva(reservaId: string): Promise<{
  phone: string;
  conversationId: string | null;
  notifiedAt: Date | null;
} | null> {
  const result = await query(
    `SELECT phone, conversation_id, notified_at
     FROM whatsapp_reserva
     WHERE reserva_id = $1`,
    [reservaId],
  );

  const row = result.rows[0];
  if (!row) return null;
  return {
    phone: row.phone,
    conversationId: row.conversation_id ?? null,
    notifiedAt: row.notified_at ?? null,
  };
}

export async function markWhatsappReservaNotified(reservaId: string): Promise<void> {
  await query(
    `UPDATE whatsapp_reserva SET notified_at = NOW() WHERE reserva_id = $1`,
    [reservaId],
  );
}

export async function getConversationHistory(conversationId: string, limit = 12): Promise<Array<{ role: 'user' | 'assistant'; content: string }>> {
  if (!conversationId) return [];

  const result = await query(
    `SELECT direction, text
     FROM whatsapp_message
     WHERE conversation_id = $1
       AND text IS NOT NULL
     ORDER BY created_at DESC
     LIMIT $2`,
    [conversationId, limit],
  );

  return result.rows
    .reverse()
    .map((row) => {
      const role = row.direction === 'OUT' ? 'assistant' : 'user';
      return {
        role: role as 'assistant' | 'user',
        content: String(row.text || '').trim(),
      };
    })
    .filter((msg) => msg.content.length > 0);
}

export async function listConversations(params?: {
  limit?: number;
  offset?: number;
  phone?: string;
}): Promise<WhatsappConversationSummary[]> {
  const limit = Math.max(1, Math.min(100, Number(params?.limit ?? 30)));
  const offset = Math.max(0, Number(params?.offset ?? 0));
  const phone = (params?.phone || '').trim();

  const values: Array<string | number> = [];
  let whereSql = '';
  if (phone) {
    values.push(`%${phone}%`);
    whereSql = `WHERE c.phone ILIKE $${values.length}`;
  }

  values.push(limit);
  const limitIndex = values.length;
  values.push(offset);
  const offsetIndex = values.length;

  const result = await query(
    `SELECT
       c.id,
       c.phone,
       c.status,
       c.last_message_at,
       c.created_at,
       m.text AS last_message_text,
       m.direction AS last_message_direction
     FROM whatsapp_conversation c
     LEFT JOIN LATERAL (
       SELECT wm.text, wm.direction
       FROM whatsapp_message wm
       WHERE wm.conversation_id = c.id
       ORDER BY wm.created_at DESC
       LIMIT 1
     ) m ON TRUE
     ${whereSql}
     ORDER BY c.last_message_at DESC NULLS LAST, c.created_at DESC
     LIMIT $${limitIndex}
     OFFSET $${offsetIndex}`,
    values,
  );

  return result.rows.map((row) => ({
    id: row.id,
    phone: row.phone,
    status: row.status,
    lastMessageAt: row.last_message_at ?? null,
    createdAt: row.created_at,
    lastMessageText: row.last_message_text ?? null,
    lastMessageDirection: row.last_message_direction ?? null,
    paused: row.status === 'PAUSED',
  }));
}

export async function listConversationMessages(params: {
  conversationId: string;
  limit?: number;
  offset?: number;
}): Promise<StoredMessage[]> {
  const limit = Math.max(1, Math.min(200, Number(params.limit ?? 50)));
  const offset = Math.max(0, Number(params.offset ?? 0));

  const result = await query(
    `SELECT id, conversation_id, direction, wa_message_id, text, status, created_at
     FROM whatsapp_message
     WHERE conversation_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [params.conversationId, limit, offset],
  );

  return result.rows.map((row) => ({
    id: row.id,
    conversationId: row.conversation_id,
    direction: row.direction,
    waMessageId: row.wa_message_id,
    text: row.text,
    status: row.status,
    createdAt: row.created_at,
  }));
}

export async function pauseConversation(conversationId: string): Promise<boolean> {
  if (!conversationId) return false;
  const result = await query(
    `UPDATE whatsapp_conversation SET status = $1 WHERE id = $2 RETURNING id`,
    ['PAUSED', conversationId],
  );
  return (result.rowCount ?? 0) > 0;
}

export async function resumeConversation(conversationId: string): Promise<boolean> {
  if (!conversationId) return false;
  const result = await query(
    `UPDATE whatsapp_conversation SET status = $1 WHERE id = $2 RETURNING id`,
    ['OPEN', conversationId],
  );
  return (result.rowCount ?? 0) > 0;
}

export async function sendManagerMessage(params: {
  conversationId: string;
  phone: string;
  text: string;
  waMessageId?: string | null;
}): Promise<StoredMessage | null> {
  return storeMessage({
    conversationId: params.conversationId,
    direction: 'OUT',
    waMessageId: params.waMessageId || null,
    text: params.text,
    status: 'sent',
  });
}
