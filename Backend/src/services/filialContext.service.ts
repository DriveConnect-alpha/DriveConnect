type FilialContextDraft = { filialId: string; expiresAt: number };

const FILIAL_CONTEXT_TTL_MS = Number.parseInt(process.env.WHATSAPP_FILIAL_CONTEXT_TTL_MS || '21600000', 10); // 6h
const filialContextByPhone = new Map<string, FilialContextDraft>();

function cleanupFilialContextDrafts(): void {
  const now = Date.now();
  for (const [key, value] of filialContextByPhone.entries()) {
    if (now > value.expiresAt) filialContextByPhone.delete(key);
  }
}

setInterval(cleanupFilialContextDrafts, Math.max(30_000, Math.floor(FILIAL_CONTEXT_TTL_MS / 2))).unref();

export function setFilialContextForPhone(phone: string, filialId: string): void {
  if (!phone || !filialId) return;
  filialContextByPhone.set(phone, { filialId, expiresAt: Date.now() + FILIAL_CONTEXT_TTL_MS });
}

export function getFilialContextForPhone(phone: string): string | null {
  const item = filialContextByPhone.get(phone);
  if (!item) return null;
  if (Date.now() > item.expiresAt) {
    filialContextByPhone.delete(phone);
    return null;
  }
  return item.filialId;
}

export function clearFilialContextForPhone(phone: string): void {
  filialContextByPhone.delete(phone);
}

export default {
  setFilialContextForPhone,
  getFilialContextForPhone,
  clearFilialContextForPhone,
};
