import { IncomingMessage, ServerResponse } from 'http';
import * as argon2 from 'argon2';
import { query } from '../db/index.js';
import { checkRole, getUserFromToken } from '../utils/auth.js';

export async function listarUsuarios(req: IncomingMessage, res: ServerResponse) {
  const currentUser = checkRole(req, res, ['ADMIN']);
  if (!currentUser) return;

  try {
    const { rows } = await query(`
      SELECT u.id, u.email, u.tipo, u.criado_em,
             c.nome_completo as cliente_nome, c.cpf as cliente_cpf,
             g.nome_completo as gerente_nome, g.filial_id as gerente_filial
      FROM usuario u
      LEFT JOIN cliente c ON u.id = c.usuario_id
      LEFT JOIN gerente g ON u.id = g.usuario_id
      WHERE u.deletado_em IS NULL
    `);

    const usuariosFormatados = rows.map(row => ({
      id: row.id,
      email: row.email,
      tipo: row.tipo,
      criado_em: row.criado_em,
      nome: row.cliente_nome || row.gerente_nome || 'Admin',
      detalhes: row.tipo === 'CLIENTE' ? { cpf: row.cliente_cpf } : (row.tipo === 'GERENTE' ? { filial_id: row.gerente_filial } : {})
    }));

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(usuariosFormatados));
  } catch (error) {
    console.error('Erro ao listar usuários:', error);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Erro interno no servidor.' }));
  }
}

export async function editarUsuario(req: IncomingMessage, res: ServerResponse, id: string) {
  const currentUser = getUserFromToken(req);
  if (!currentUser) {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Não autorizado.' }));
    return;
  }

  // Apenas Admin pode editar outros usuários. Usuário comum edita apenas a si mesmo.
  const isSelf = currentUser.id === id;
  const isAdmin = currentUser.tipo === 'ADMIN';

  if (!isSelf && !isAdmin) {
    res.writeHead(403, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Acesso negado. Você só pode editar seu próprio perfil.' }));
    return;
  }

  const corpo = await lerCorpo(req);
  const { nome, email, novaSenha } = corpo;

  try {
    if (email) {
      await query('UPDATE usuario SET email = $1 WHERE id = $2', [email, id]);
    }

    if (novaSenha) {
      const hashedPassword = await argon2.hash(novaSenha);
      await query('UPDATE usuario SET senha = $1 WHERE id = $2', [hashedPassword, id]);
    }

    if (nome) {
      // Tenta atualizar como cliente
      const resultCliente = await query('UPDATE cliente SET nome_completo = $1 WHERE usuario_id = $2', [nome, id]);
      if (resultCliente.rowCount === 0) {
        // Se não era cliente, tenta como gerente ou admin
        await query('UPDATE gerente SET nome_completo = $1 WHERE usuario_id = $2', [nome, id]);
      }
    }

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ mensagem: 'Usuário atualizado com sucesso.' }));
  } catch (error) {
    console.error('Erro ao editar usuário:', error);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Erro interno no servidor.' }));
  }
}

export async function desativarUsuario(req: IncomingMessage, res: ServerResponse, id: string) {
  const currentUser = getUserFromToken(req);
  if (!currentUser) {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Não autorizado.' }));
    return;
  }

  const isSelf = currentUser.id === id;
  const isAdmin = currentUser.tipo === 'ADMIN';

  if (!isSelf && !isAdmin) {
    res.writeHead(403, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Acesso negado. Você só pode desativar seu próprio perfil.' }));
    return;
  }

  try {
    // Soft delete na tabela usuario
    await query('UPDATE usuario SET deletado_em = CURRENT_TIMESTAMP WHERE id = $1', [id]);
    
    // Soft delete nas tabelas relacionadas
    await query('UPDATE cliente SET deletado_em = CURRENT_TIMESTAMP WHERE usuario_id = $1', [id]);
    await query('UPDATE gerente SET deletado_em = CURRENT_TIMESTAMP WHERE usuario_id = $1', [id]);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ mensagem: 'Usuário desativado com sucesso.' }));
  } catch (error) {
    console.error('Erro ao desativar usuário:', error);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Erro interno no servidor.' }));
  }
}

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
