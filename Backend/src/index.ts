import 'dotenv/config';
import { createServer, IncomingMessage, ServerResponse } from 'http';
import { login, register, registerManager } from './routes/auth.routes.js';
import { checarDisponibilidade, confirmarRetirada, confirmarDevolucao } from './routes/reserva.routes.js';
import { iniciarPagamento, receberWebhook, statusPagamento } from './routes/payment.routes.js';
import { listarSeguros, criarSeguro, atualizarSeguro, desativarSeguro } from './routes/seguro.routes.js';
import { listarUsuarios, editarUsuario, desativarUsuario } from './routes/user.routes.js';
import { listarFiliais } from './routes/filial.routes.js';

const PORT = process.env.PORT || 3000;

const server = createServer(async (req: IncomingMessage, res: ServerResponse) => {
  const url = new URL(req.url ?? '', `http://${req.headers.host}`);
  const method = req.method;
  const path = url.pathname;

  // CORS - Importante para o Flutter Web ou Emuladores
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  try {
    // --- ROTAS DE AUTENTICAÇÃO ---
    if (path === '/auth/login' && method === 'POST') {
      return await login(req, res);
    }

    if (path === '/auth/register' && method === 'POST') {
      return await register(req, res);
    }

    if (path === '/auth/register-manager' && method === 'POST') {
      return await registerManager(req, res);
    }

    // --- ROTAS DE USUÁRIOS (ADMIN) ---
    if (path === '/usuarios' && method === 'GET') {
      return await listarUsuarios(req, res);
    }

    if (path.startsWith('/usuarios/') && method === 'PUT') {
      const id = path.split('/')[2];
      if (id) return await editarUsuario(req, res, id);
    }

    if (path.startsWith('/usuarios/') && method === 'DELETE') {
      const id = path.split('/')[2];
      if (id) return await desativarUsuario(req, res, id);
    }

    // --- ROTAS DE FILIAIS ---
    if (path === '/filiais' && method === 'GET') {
      return await listarFiliais(req, res);
    }

    // --- ROTAS DE RESERVA ---
    if (path === '/reservas/disponibilidade' && method === 'GET') {
      return await checarDisponibilidade(req, res);
    }
    
    if (path.startsWith('/reservas/') && path.endsWith('/retirada') && method === 'POST') {
      const id = path.split('/')[2];
      if (id) return await confirmarRetirada(req, res, id);
    }

    if (path.startsWith('/reservas/') && path.endsWith('/devolucao') && method === 'POST') {
      const id = path.split('/')[2];
      if (id) return await confirmarDevolucao(req, res, id);
    }

    // --- ROTAS DE PAGAMENTO ---
    if (path === '/pagamento/iniciar' && method === 'POST') {
      return await iniciarPagamento(req, res);
    }

    if (path === '/pagamento/webhook' && method === 'POST') {
      return await receberWebhook(req, res);
    }

    if (path.startsWith('/pagamento/status/') && method === 'GET') {
      const id = path.split('/')[3];
      if (id) return await statusPagamento(req, res, id);
    }

    // --- ROTAS DE SEGURO ---
    if (path === '/seguros') {
      if (method === 'GET') return await listarSeguros(req, res);
      if (method === 'POST') return await criarSeguro(req, res);
    }

    if (path.startsWith('/seguros/') && method === 'PUT') {
      const id = path.split('/')[2];
      if (id) return await atualizarSeguro(req, res, id);
    }

    if (path.startsWith('/seguros/') && method === 'DELETE') {
      const id = path.split('/')[2];
      if (id) return await desativarSeguro(req, res, id);
    }

    // Rota não encontrada
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Rota não encontrada.' }));

  } catch (error) {
    console.error('Erro no servidor:', error);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Erro interno no servidor.' }));
  }
});

server.listen(PORT, () => {
  console.log(`🚀 Drive Connect Backend rodando na porta ${PORT}`);
});
