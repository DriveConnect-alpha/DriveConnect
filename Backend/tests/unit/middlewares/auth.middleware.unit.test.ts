/// <reference types="node" />
import { describe, it, expect } from '@jest/globals';
import { extractCaller, requireCaller, requireTipo, requireOwnership, type Caller } from '../../../src/middlewares/auth';
import type { IncomingMessage } from 'http';

/**
 * Unit tests for authentication middleware and guards.
 */
describe('Auth Middleware Unit Tests', () => {
  describe('extractCaller', () => {
    it('should extract caller from valid headers', () => {
      const mockReq = {
        headers: {
          'x-usuario-id': 'user-123',
          'x-tipo': 'ADMIN',
          'x-filial-id': 'filial-456',
        }
      } as unknown as IncomingMessage;

      const result = extractCaller(mockReq);

      expect(result).toEqual({
        usuarioId: 'user-123',
        tipo: 'ADMIN',
        filialId: 'filial-456',
      });
    });

    it('should return null if x-usuario-id is missing', () => {
      const mockReq = {
        headers: {
          'x-tipo': 'ADMIN',
        }
      } as unknown as IncomingMessage;

      expect(extractCaller(mockReq)).toBeNull();
    });

    it('should return null if x-usuario-id is an empty string', () => {
      const mockReq = {
        headers: {
          'x-usuario-id': '  ',
          'x-tipo': 'ADMIN',
        }
      } as unknown as IncomingMessage;

      expect(extractCaller(mockReq)).toBeNull();
    });

    it('should return null if x-tipo is invalid', () => {
      const mockReq = {
        headers: {
          'x-usuario-id': 'user-123',
          'x-tipo': 'INVALID_TYPE',
        }
      } as unknown as IncomingMessage;

      expect(extractCaller(mockReq)).toBeNull();
    });

    it('should set filialId to null if x-filial-id header is missing', () => {
      const mockReq = {
        headers: {
          'x-usuario-id': 'user-123',
          'x-tipo': 'CLIENTE',
        }
      } as unknown as IncomingMessage;

      const result = extractCaller(mockReq);
      expect(result).not.toBeNull();
      expect(result?.filialId).toBeNull();
    });

    it('should set filialId to null if x-filial-id header is empty', () => {
      const mockReq = {
        headers: {
          'x-usuario-id': 'user-123',
          'x-tipo': 'GERENTE',
          'x-filial-id': '  ',
        }
      } as unknown as IncomingMessage;

      const result = extractCaller(mockReq);
      expect(result).not.toBeNull();
      expect(result?.filialId).toBeNull();
    });
  });

  describe('requireCaller', () => {
    it('should return caller if valid headers are present', () => {
      const mockReq = {
        headers: {
          'x-usuario-id': 'user-123',
          'x-tipo': 'CLIENTE',
        }
      } as unknown as IncomingMessage;

      const result = requireCaller(mockReq);
      expect(result.usuarioId).toBe('user-123');
      expect(result.tipo).toBe('CLIENTE');
    });

    it('should throw error if identity is missing', () => {
      const mockReq = { 
        headers: {} 
      } as unknown as IncomingMessage;
      
      expect(() => requireCaller(mockReq)).toThrow('Não autorizado: identidade ausente ou inválida.');
    });
  });

  describe('requireTipo', () => {
    const mockCaller: Caller = { usuarioId: '1', tipo: 'CLIENTE', filialId: null };

    it('should pass if caller type is in allowed list', () => {
      expect(() => requireTipo(mockCaller, 'CLIENTE', 'ADMIN')).not.toThrow();
    });

    it('should throw if caller type is not in allowed list', () => {
      expect(() => requireTipo(mockCaller, 'ADMIN', 'GERENTE')).toThrow('Sem permissão para acessar este recurso.');
    });
  });

  describe('requireOwnership', () => {
    const mockCaller: Caller = { usuarioId: 'user-123', tipo: 'CLIENTE', filialId: null };

    it('should pass if caller is the owner', () => {
      expect(() => requireOwnership(mockCaller, 'user-123')).not.toThrow();
    });

    it('should pass if caller has a privileged type', () => {
      // Mocking a GERENTE caller
      const gerenteCaller: Caller = { usuarioId: 'gerente-1', tipo: 'GERENTE', filialId: 'f1' };
      expect(() => requireOwnership(gerenteCaller, 'some-other-user', 'GERENTE', 'ADMIN')).not.toThrow();
    });

    it('should throw if caller is not owner and has no privileged type', () => {
      expect(() => requireOwnership(mockCaller, 'other-user', 'ADMIN')).toThrow('Sem permissão: você só pode acessar seus próprios dados.');
    });
  });
});
