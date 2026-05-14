import 'dotenv/config';
import fs from 'fs';
import { cert, getApps, initializeApp, type App, type ServiceAccount } from 'firebase-admin/app';
import { getMessaging, type BatchResponse, type Messaging, type MulticastMessage } from 'firebase-admin/messaging';
import { query } from '../db/index.js';

let firebaseApp: App | null = null;
let firebaseDisabledLogged = false;
let firebaseSendDisabledLogged = false;

function maskToken(token: string): string {
  if (!token) return '';
  const t = String(token);
  if (t.length <= 10) return `${t.slice(0, 2)}…${t.slice(-2)}`;
  return `${t.slice(0, 4)}…${t.slice(-4)}`;
}

function getServiceAccount(): ServiceAccount | null {
  const jsonFromEnv = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const base64FromEnv = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  const pathFromEnv = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (jsonFromEnv && jsonFromEnv.trim()) {
    return JSON.parse(jsonFromEnv) as ServiceAccount;
  }

  if (base64FromEnv && base64FromEnv.trim()) {
    const decoded = Buffer.from(base64FromEnv, 'base64').toString('utf8');
    return JSON.parse(decoded) as ServiceAccount;
  }

  if (pathFromEnv && pathFromEnv.trim()) {
    const raw = fs.readFileSync(pathFromEnv, 'utf8');
    return JSON.parse(raw) as ServiceAccount;
  }

  return null;
}

function getFirebaseApp(): App | null {
  if (firebaseApp) return firebaseApp;

  const serviceAccount = getServiceAccount();
  if (!serviceAccount) {
    if (!firebaseDisabledLogged) {
      console.warn('[FCM] Firebase não configurado. Configure FIREBASE_SERVICE_ACCOUNT_JSON/PATH/BASE64.');
      firebaseDisabledLogged = true;
    }
    return null;
  }

  const existing = getApps()[0];
  firebaseApp = existing ?? initializeApp({
    credential: cert(serviceAccount),
  });

  return firebaseApp;
}

type MessagingClient = Messaging & {
  sendEachForMulticast?: (message: MulticastMessage, dryRun?: boolean) => Promise<BatchResponse>;
  sendMulticast?: (message: MulticastMessage, dryRun?: boolean) => Promise<BatchResponse>;
};

function getMessagingClient(): MessagingClient | null {
  const app = getFirebaseApp();
  return app ? (getMessaging(app) as MessagingClient) : null;
}

function toDataPayload(data: Record<string, unknown>): Record<string, string> {
  const payload: Record<string, string> = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === undefined || value === null) continue;
    payload[key] = String(value);
  }
  return payload;
}

export async function saveFcmToken(params: {
  usuarioId: string;
  token: string;
  plataforma?: string;
  deviceId?: string;
}): Promise<void> {
  const { usuarioId, token, plataforma, deviceId } = params;
  if (!usuarioId || !token) throw new Error('Token ou usuário inválido.');

  await query(
    `INSERT INTO fcm_token (usuario_id, token, plataforma, device_id)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (token) DO UPDATE SET
        usuario_id = EXCLUDED.usuario_id,
        plataforma = EXCLUDED.plataforma,
        device_id = EXCLUDED.device_id,
        atualizado_em = NOW()`
    , [usuarioId, token, plataforma ?? null, deviceId ?? null],
  );
}

export async function deleteFcmToken(params: { usuarioId: string; token: string }): Promise<void> {
  const { usuarioId, token } = params;
  if (!usuarioId || !token) return;
  await query(
    `DELETE FROM fcm_token WHERE usuario_id = $1 AND token = $2`,
    [usuarioId, token],
  );
}

async function deleteInvalidTokens(tokens: string[]): Promise<void> {
  if (!tokens.length) return;
  await query(
    `DELETE FROM fcm_token WHERE token = ANY($1)`,
    [tokens],
  );
}

async function listTokensForFilial(filialId: string): Promise<string[]> {
  if (!filialId) return [];
  const result = await query(
    `SELECT DISTINCT ft.token
     FROM fcm_token ft
     JOIN usuario u ON u.id = ft.usuario_id
     LEFT JOIN gerente g ON g.usuario_id = u.id
     WHERE u.deletado_em IS NULL
       AND (
         (u.tipo = 'GERENTE' AND g.deletado_em IS NULL AND (g.filial_id = $1 OR g.filial_id IS NULL))
         OR u.tipo = 'ADMIN'
       )`,
    [filialId],
  );
  return result.rows.map((row) => String(row.token)).filter(Boolean);
}

async function listTokensForUsuario(usuarioId: string): Promise<string[]> {
  if (!usuarioId) return [];
  const result = await query(
    `SELECT DISTINCT ft.token
     FROM fcm_token ft
     JOIN usuario u ON u.id = ft.usuario_id
     WHERE ft.usuario_id = $1
       AND u.deletado_em IS NULL`,
    [usuarioId],
  );
  return result.rows.map((row) => String(row.token)).filter(Boolean);
}

async function listTokensForAllManagers(): Promise<string[]> {
  const result = await query(
    `SELECT DISTINCT ft.token
     FROM fcm_token ft
     JOIN usuario u ON u.id = ft.usuario_id
     LEFT JOIN gerente g ON g.usuario_id = u.id
     WHERE u.deletado_em IS NULL
       AND (
         (u.tipo = 'GERENTE' AND g.deletado_em IS NULL)
         OR u.tipo = 'ADMIN'
       )`,
  );
  return result.rows.map((row) => String(row.token)).filter(Boolean);
}

async function resolveUsuarioIdFromClienteOrUsuarioId(id: string): Promise<string | null> {
  if (!id) return null;

  // 1) Se já for um usuário, retorna.
  const user = await query(
    `SELECT id FROM usuario WHERE id = $1 AND deletado_em IS NULL LIMIT 1`,
    [id],
  );
  if (user.rows[0]?.id) return String(user.rows[0].id);

  // 2) Se for cliente.id, resolve para cliente.usuario_id
  const cliente = await query(
    `SELECT usuario_id FROM cliente WHERE id = $1 AND deletado_em IS NULL LIMIT 1`,
    [id],
  );
  const usuarioId = cliente.rows[0]?.usuario_id;
  return usuarioId ? String(usuarioId) : null;
}

async function sendMulticastNotification(params: {
  tokens: string[];
  notification: { title: string; body: string };
  data: Record<string, unknown>;
}): Promise<void> {
  const { tokens, notification, data } = params;
  if (tokens.length === 0) return;

  const messaging = getMessagingClient();
  if (!messaging) {
    if (!firebaseSendDisabledLogged) {
      console.warn('[FCM] Envio desabilitado (firebase-admin não configurado).');
      firebaseSendDisabledLogged = true;
    }
    return;
  }

  const tipo = typeof (data as any)?.tipo === 'string' ? String((data as any).tipo) : '';
  const reservaId = typeof (data as any)?.reservaId === 'string' ? String((data as any).reservaId) : '';
  const filialId = typeof (data as any)?.filialId === 'string' ? String((data as any).filialId) : '';
  const origem = typeof (data as any)?.origem === 'string' ? String((data as any).origem) : '';

  console.log(
    `[FCM] Enviando: title="${notification.title}" tipo="${tipo}" tokens=${tokens.length}` +
      `${reservaId ? ` reservaId=${reservaId}` : ''}` +
      `${filialId ? ` filialId=${filialId}` : ''}` +
      `${origem ? ` origem=${origem}` : ''}`,
  );

  const multicastMessage: MulticastMessage = {
    tokens,
    notification,
    data: toDataPayload(data),
  };

  const response = messaging.sendEachForMulticast
    ? await messaging.sendEachForMulticast(multicastMessage)
    : await messaging.sendMulticast?.(multicastMessage);

  if (!response) return;

  console.log(`[FCM] Resultado: success=${response.successCount} failure=${response.failureCount}`);

  if (response.failureCount > 0) {
    const invalidTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (resp.success) return;
      const err: any = resp.error as any;
      const code = err?.code ? String(err.code) : 'unknown';
      const msg = err?.message ? String(err.message) : 'unknown';
      console.warn(`[FCM] Falha token=${maskToken(tokens[idx])} code=${code} msg=${msg}`);

      if (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token') {
        const token = tokens[idx];
        if (token) invalidTokens.push(token);
      }
    });
    if (invalidTokens.length > 0) {
      await deleteInvalidTokens(invalidTokens);
      console.warn(`[FCM] Tokens inválidos removidos: ${invalidTokens.length}`);
    }
  }
}

async function notifyManagers(params: {
  filialId: string;
  notification: { title: string; body: string };
  data: Record<string, unknown>;
}): Promise<void> {
  const tokens = await listTokensForFilial(params.filialId);
  console.log(`[FCM] Tokens gerentes/admin filialId=${params.filialId}: ${tokens.length}`);
  await sendMulticastNotification({
    tokens,
    notification: params.notification,
    data: params.data,
  });
}

async function notifyUsuario(params: {
  usuarioId: string;
  notification: { title: string; body: string };
  data: Record<string, unknown>;
}): Promise<void> {
  const tokens = await listTokensForUsuario(params.usuarioId);
  console.log(`[FCM] Tokens usuário usuarioId=${params.usuarioId}: ${tokens.length}`);
  await sendMulticastNotification({
    tokens,
    notification: params.notification,
    data: params.data,
  });
}

export async function notifyVeiculoStatusAlteradoAllManagers(params: {
  veiculoId: string;
  placa?: string;
  statusAnterior?: string | null;
  statusNovo: string;
  filialId?: string | null;
  filialNome?: string | null;
  cidade?: string | null;
  uf?: string | null;
  modelo?: string | null;
  origem?: string;
  motivo?: string;
}): Promise<void> {
  const tokens = await listTokensForAllManagers();
  console.log(`[FCM] Tokens todos gerentes/admin: ${tokens.length}`);

  const local = [params.filialNome, params.cidade, params.uf].filter(Boolean).join(' / ');
  const header = [params.placa, params.modelo].filter(Boolean).join(' - ');
  const fromTo = params.statusAnterior ? `${params.statusAnterior} → ${params.statusNovo}` : params.statusNovo;
  const bodyParts = [
    header ? `${header}: ${fromTo}` : `Status do veículo: ${fromTo}`,
    local ? `Unidade: ${local}` : null,
    params.motivo ? `Motivo: ${params.motivo}` : null,
  ].filter(Boolean);

  await sendMulticastNotification({
    tokens,
    notification: {
      title: 'Status do veículo atualizado',
      body: bodyParts.join(' | '),
    },
    data: {
      tipo: 'VEICULO_STATUS_ALTERADO',
      veiculoId: params.veiculoId,
      placa: params.placa,
      statusAnterior: params.statusAnterior ?? null,
      statusNovo: params.statusNovo,
      filialId: params.filialId ?? null,
      origem: params.origem ?? 'BACKEND',
      motivo: params.motivo ?? null,
    },
  });
}

export async function notifyVeiculoStatusAlteradoBulkAllManagers(params: {
  statusNovo: string;
  quantidade: number;
  placas?: string[];
  origem?: string;
  motivo?: string;
}): Promise<void> {
  const tokens = await listTokensForAllManagers();
  console.log(`[FCM] Tokens todos gerentes/admin: ${tokens.length}`);

  const placas = (params.placas || []).filter(Boolean);
  const preview = placas.length ? ` Placas: ${placas.slice(0, 5).join(', ')}${placas.length > 5 ? '…' : ''}` : '';
  const motivo = params.motivo ? ` Motivo: ${params.motivo}` : '';

  await sendMulticastNotification({
    tokens,
    notification: {
      title: 'Frota atualizada',
      body: `${params.quantidade} veículo(s) agora estão como ${params.statusNovo}.${preview}${motivo}`.trim(),
    },
    data: {
      tipo: 'VEICULO_STATUS_BULK',
      statusNovo: params.statusNovo,
      quantidade: params.quantidade,
      origem: params.origem ?? 'BACKEND',
      motivo: params.motivo ?? null,
    },
  });
}

export async function notifyNovoServicoPendente(params: {
  reservaId: string;
  filialId: string;
  clienteNome?: string;
  modelo?: string;
  dataInicio?: Date;
  dataFim?: Date;
  origem?: string;
}): Promise<void> {
  const { reservaId, filialId, clienteNome, modelo, dataInicio, dataFim, origem } = params;
  if (!reservaId || !filialId) return;

  const inicio = dataInicio ? dataInicio.toISOString() : null;
  const fim = dataFim ? dataFim.toISOString() : null;

  await notifyManagers({
    filialId,
    notification: {
      title: 'Novo Serviço Pendente',
      body: 'Uma nova reserva está aguardando confirmação.',
    },
    data: {
      tipo: 'NOVO_SERVICO_PENDENTE',
      reservaId,
      filialId,
      origem: origem ?? 'APP',
      clienteNome,
      modelo,
      dataInicio: inicio,
      dataFim: fim,
      status: 'PENDENTE_PAGAMENTO',
    },
  });
}

export async function notifyReservaPendente(params: {
  reservaId: string;
  filialId: string;
  clienteId: string;
  clienteNome?: string;
  modelo?: string;
  dataInicio?: Date;
  dataFim?: Date;
  origem?: string;
}): Promise<void> {
  const { reservaId, filialId, clienteId, clienteNome, modelo, dataInicio, dataFim, origem } = params;
  if (!reservaId || !filialId || !clienteId) return;

  const inicio = dataInicio ? dataInicio.toISOString() : null;
  const fim = dataFim ? dataFim.toISOString() : null;
  const usuarioId = await resolveUsuarioIdFromClienteOrUsuarioId(clienteId);

  const managerParams: {
    reservaId: string;
    filialId: string;
    clienteNome?: string;
    modelo?: string;
    dataInicio?: Date;
    dataFim?: Date;
    origem?: string;
  } = { reservaId, filialId };
  if (origem) managerParams.origem = origem;
  if (clienteNome) managerParams.clienteNome = clienteNome;
  if (modelo) managerParams.modelo = modelo;
  if (dataInicio) managerParams.dataInicio = dataInicio;
  if (dataFim) managerParams.dataFim = dataFim;

  await Promise.all([
    notifyNovoServicoPendente(managerParams),
    ...(usuarioId ? [notifyUsuario({
      usuarioId,
      notification: {
        title: 'Reserva pendente',
        body: 'Seu pagamento está aguardando confirmação.',
      },
      data: {
        tipo: 'RESERVA_PENDENTE',
        reservaId,
        filialId,
        origem: origem ?? 'APP',
        clienteNome,
        modelo,
        dataInicio: inicio,
        dataFim: fim,
        status: 'PENDENTE_PAGAMENTO',
      },
    })] : []),
  ]);
}

export async function notifyPagamentoConfirmado(params: {
  reservaId: string;
  filialId: string;
  clienteId: string;
  clienteNome?: string;
  modelo?: string;
  dataInicio?: Date;
  dataFim?: Date;
  origem?: string;
}): Promise<void> {
  const { reservaId, filialId, clienteId, clienteNome, modelo, dataInicio, dataFim, origem } = params;
  if (!reservaId || !filialId || !clienteId) return;

  const inicio = dataInicio ? dataInicio.toISOString() : null;
  const fim = dataFim ? dataFim.toISOString() : null;
  const usuarioId = await resolveUsuarioIdFromClienteOrUsuarioId(clienteId);

  await Promise.all([
    notifyManagers({
      filialId,
      notification: {
        title: 'Locação aprovada',
        body: 'Pagamento confirmado. Reserva aprovada.',
      },
      data: {
        tipo: 'LOCACAO_APROVADA',
        reservaId,
        filialId,
        origem: origem ?? 'INFINITEPAY',
        clienteNome,
        modelo,
        dataInicio: inicio,
        dataFim: fim,
        status: 'RESERVADA',
      },
    }),
    ...(usuarioId ? [notifyUsuario({
      usuarioId,
      notification: {
        title: 'Pagamento confirmado',
        body: 'Sua reserva foi confirmada com sucesso.',
      },
      data: {
        tipo: 'PAGAMENTO_CONFIRMADO',
        reservaId,
        filialId,
        origem: origem ?? 'INFINITEPAY',
        clienteNome,
        modelo,
        dataInicio: inicio,
        dataFim: fim,
        status: 'RESERVADA',
      },
    })] : []),
  ]);
}

export async function notifyReservaCancelada(params: {
  reservaId: string;
  filialId: string;
  clienteId: string;
  clienteNome?: string | undefined;
  modelo?: string | undefined;
  dataInicio?: Date | undefined;
  dataFim?: Date | undefined;
  origem?: string | undefined;
}): Promise<void> {
  const { reservaId, filialId, clienteId, clienteNome, modelo, dataInicio, dataFim, origem } = params;
  if (!reservaId || !filialId || !clienteId) return;

  const inicio = dataInicio ? dataInicio.toISOString() : null;
  const fim = dataFim ? dataFim.toISOString() : null;
  const usuarioId = await resolveUsuarioIdFromClienteOrUsuarioId(clienteId);

  await Promise.all([
    notifyManagers({
      filialId,
      notification: {
        title: 'Reserva cancelada',
        body: 'Uma reserva foi cancelada.',
      },
      data: {
        tipo: 'RESERVA_CANCELADA',
        reservaId,
        filialId,
        origem: origem ?? 'APP',
        clienteNome,
        modelo,
        dataInicio: inicio,
        dataFim: fim,
        status: 'CANCELADA',
      },
    }),
    ...(usuarioId ? [notifyUsuario({
      usuarioId,
      notification: {
        title: 'Reserva cancelada',
        body: 'Sua reserva foi cancelada.',
      },
      data: {
        tipo: 'RESERVA_CANCELADA',
        reservaId,
        filialId,
        origem: origem ?? 'APP',
        clienteNome,
        modelo,
        dataInicio: inicio,
        dataFim: fim,
        status: 'CANCELADA',
      },
    })] : []),
  ]);
}

export async function notifyReservaExpirada(params: {
  reservaId: string;
  filialId: string;
  clienteId: string;
  clienteNome?: string;
  modelo?: string;
  dataInicio?: Date;
  dataFim?: Date;
  origem?: string;
}): Promise<void> {
  const { reservaId, filialId, clienteId, clienteNome, modelo, dataInicio, dataFim, origem } = params;
  if (!reservaId || !filialId || !clienteId) return;

  const inicio = dataInicio ? dataInicio.toISOString() : null;
  const fim = dataFim ? dataFim.toISOString() : null;
  const usuarioId = await resolveUsuarioIdFromClienteOrUsuarioId(clienteId);

  await Promise.all([
    notifyManagers({
      filialId,
      notification: {
        title: 'Reserva expirada',
        body: 'Uma reserva pendente expirou.',
      },
      data: {
        tipo: 'RESERVA_EXPIRADA',
        reservaId,
        filialId,
        origem: origem ?? 'APP',
        clienteNome,
        modelo,
        dataInicio: inicio,
        dataFim: fim,
        status: 'EXPIRADA',
      },
    }),
    ...(usuarioId ? [notifyUsuario({
      usuarioId,
      notification: {
        title: 'Reserva expirada',
        body: 'Seu pagamento não foi confirmado a tempo.',
      },
      data: {
        tipo: 'RESERVA_EXPIRADA',
        reservaId,
        filialId,
        origem: origem ?? 'APP',
        clienteNome,
        modelo,
        dataInicio: inicio,
        dataFim: fim,
        status: 'EXPIRADA',
      },
    })] : []),
  ]);
}
