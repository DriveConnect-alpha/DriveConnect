import { IncomingMessage, ServerResponse } from 'http';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key';

export interface DecodedToken {
  id: string;
  email: string;
  tipo: 'CLIENTE' | 'GERENTE' | 'ADMIN';
  iat?: number;
  exp?: number;
}

export function getUserFromToken(req: IncomingMessage): DecodedToken | null {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.split(' ')[1];
  try {
    return jwt.verify(token, JWT_SECRET) as DecodedToken;
  } catch {
    return null;
  }
}

export function checkRole(req: IncomingMessage, res: ServerResponse, allowedRoles: ('CLIENTE' | 'GERENTE' | 'ADMIN')[]): DecodedToken | null {
  const user = getUserFromToken(req);
  
  if (!user) {
    res.writeHead(401, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Não autorizado. Token não fornecido ou inválido.' }));
    return null;
  }

  if (!allowedRoles.includes(user.tipo)) {
    res.writeHead(403, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ erro: 'Acesso negado. Você não tem permissão para realizar esta ação.' }));
    return null;
  }

  return user;
}
