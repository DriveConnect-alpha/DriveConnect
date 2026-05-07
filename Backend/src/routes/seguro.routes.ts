import { IncomingMessage, ServerResponse } from 'http';
import {
  listarPlanos,
  criarPlano,
  atualizarPlano,
  desativarPlano,
} from '../services/seguro.service.js';

import { requireCaller, requireTipo } from '../middlewares/auth.js';

function lerCorpo(req: IncomingMessage): Promise<Record<string, any>> {
  return new Promise((resolve, reject) => {
    let dados = '';
    req.on('data', (chunk) => (dados += chunk));
    req.on('end', () => {
      try { resolve(JSON.parse(dados || '{}')); }
      catch { reject(new Error('JSON inválido no corpo da requisição.')); }
    });
    req.on('error', reject);
  });
}

// ──────────────────────────────────────────────
// GET /seguros
// Lista todos os planos de seguro ativos da empresa.
// O plano Básico (obrigatório) sempre aparece primeiro.
// ──────────────────────────────────────────────
export async function listarSeguros(_req: IncomingMessage, res: ServerResponse) {
  const planos = await listarPlanos();

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(planos));
}

// ──────────────────────────────────────────────
// POST /seguros
// Cria um novo plano de seguro global da empresa.
// Body: { nome, descricao?, percentual, obrigatorio? }
// ──────────────────────────────────────────────
export async function criarSeguro(req: IncomingMessage, res: ServerResponse) {
  try {
    const caller = requireCaller(req);
    requireTipo(caller, 'ADMIN');

    const corpo = await lerCorpo(req);
  const { nome, descricao, percentual, obrigatorio } = corpo;

  if (!nome || percentual === undefined) {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Campos obrigatórios: nome, percentual.' }));
    return;
  }

  if (typeof percentual !== 'number' || percentual < 0 || percentual > 100) {
    res.writeHead(400, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'percentual deve ser um número entre 0 e 100.' }));
    return;
  }

  const plano = await criarPlano({ nome, descricao, percentual, obrigatorio });

    res.writeHead(201, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(plano));
  } catch (err: any) {
    const mensagem = err.message || 'Erro interno.';
    res.writeHead(err.message?.includes('autorizado') ? 401 : 500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: mensagem }));
  }
}

// ──────────────────────────────────────────────
// PUT /seguros/:id
// Atualiza nome, descrição ou percentual de um plano.
// Body: { nome?, descricao?, percentual? }
// ──────────────────────────────────────────────
export async function atualizarSeguro(req: IncomingMessage, res: ServerResponse, planoId: string) {
  try {
    const caller = requireCaller(req);
    requireTipo(caller, 'ADMIN');

    const corpo = await lerCorpo(req);
  const { nome, descricao, percentual } = corpo;

  const planoAtualizado = await atualizarPlano(planoId, { nome, descricao, percentual });

  if (!planoAtualizado) {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Plano não encontrado ou sem campos para atualizar.' }));
    return;
  }

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(planoAtualizado));
  } catch (err: any) {
    const mensagem = err.message || 'Erro interno.';
    res.writeHead(err.message?.includes('autorizado') ? 401 : 500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: mensagem }));
  }
}

// ──────────────────────────────────────────────
// DELETE /seguros/:id
// Desativa (soft delete) um plano de seguro.
// Planos obrigatórios (Básico) não podem ser desativados.
// ──────────────────────────────────────────────
export async function desativarSeguro(req: IncomingMessage, res: ServerResponse, planoId: string) {
  try {
    const caller = requireCaller(req);
    requireTipo(caller, 'ADMIN');

    const resultado = await desativarPlano(planoId);

  if (!resultado.sucesso) {
    res.writeHead(409, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: resultado.motivo }));
    return;
  }

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ mensagem: 'Plano desativado com sucesso.' }));
  } catch (err: any) {
    const mensagem = err.message || 'Erro interno.';
    res.writeHead(err.message?.includes('autorizado') ? 401 : 500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: mensagem }));
  }
}
