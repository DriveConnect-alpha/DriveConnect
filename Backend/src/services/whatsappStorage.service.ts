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
