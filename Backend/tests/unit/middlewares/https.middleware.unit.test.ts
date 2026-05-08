/// <reference types="node" />
import { jest, describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import type { IncomingMessage, ServerResponse } from 'http';

/**
 * Unit tests for HTTPS enforcement middleware.
 * Using dynamic imports to test different NODE_ENV and process.env values.
 */
describe('HTTPS Middleware Unit Tests', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
    jest.clearAllMocks();
  });

  it('should be a no-op in development environment', async () => {
    process.env.NODE_ENV = 'development';
    const { enforceHttps } = await import('../../../src/middlewares/https');

    const mockReq = {} as IncomingMessage;
    const mockRes = {} as ServerResponse;

    const result = enforceHttps(mockReq, mockRes);
    expect(result).toBe(false);
  });

  describe('Production Environment', () => {
    beforeEach(() => {
      process.env.NODE_ENV = 'production';
    });

    describe('Direct Server (not behind proxy)', () => {
      beforeEach(() => {
        process.env.HTTPS_BEHIND_PROXY = 'false';
      });

      it('should allow secure requests', async () => {
        const { enforceHttps } = await import('../../../src/middlewares/https');
        const mockReq = {
          socket: { encrypted: true }
        } as unknown as IncomingMessage;
        const mockRes = {} as ServerResponse;

        const result = enforceHttps(mockReq, mockRes);
        expect(result).toBe(false);
      });

      it('should redirect insecure requests', async () => {
        const { enforceHttps } = await import('../../../src/middlewares/https');
        const mockReq = {
          socket: { encrypted: false },
          headers: { host: 'example.com' },
          url: '/test'
        } as unknown as IncomingMessage;

        const mockRes = {
          writeHead: jest.fn(),
          end: jest.fn(),
        } as unknown as ServerResponse;

        const result = enforceHttps(mockReq, mockRes);
        
        expect(result).toBe(true);
        expect(mockRes.writeHead).toHaveBeenCalledWith(301, expect.objectContaining({
          Location: 'https://example.com/test'
        }));
      });
    });

    describe('Behind Proxy', () => {
      beforeEach(() => {
        process.env.HTTPS_BEHIND_PROXY = 'true';
      });

      it('should allow secure requests (X-Forwarded-Proto: https)', async () => {
        const { enforceHttps } = await import('../../../src/middlewares/https');
        const mockReq = {
          headers: { 'x-forwarded-proto': 'https' }
        } as unknown as IncomingMessage;
        const mockRes = {} as ServerResponse;

        const result = enforceHttps(mockReq, mockRes);
        expect(result).toBe(false);
      });

      it('should redirect insecure requests', async () => {
        const { enforceHttps } = await import('../../../src/middlewares/https');
        const mockReq = {
          headers: { 
            'x-forwarded-proto': 'http',
            'x-forwarded-host': 'proxy.com'
          },
          url: '/api'
        } as unknown as IncomingMessage;

        const mockRes = {
          writeHead: jest.fn(),
          end: jest.fn(),
        } as unknown as ServerResponse;

        const result = enforceHttps(mockReq, mockRes);
        
        expect(result).toBe(true);
        expect(mockRes.writeHead).toHaveBeenCalledWith(301, expect.objectContaining({
          Location: 'https://proxy.com/api'
        }));
      });

      it('should fallback to host header if x-forwarded-host is missing', async () => {
        const { enforceHttps } = await import('../../../src/middlewares/https');
        const mockReq = {
          headers: { 
            'x-forwarded-proto': 'http',
            'host': 'fallback.com'
          },
          url: '/'
        } as unknown as IncomingMessage;

        const mockRes = {
          writeHead: jest.fn(),
          end: jest.fn(),
        } as unknown as ServerResponse;

        enforceHttps(mockReq, mockRes);
        
        expect(mockRes.writeHead).toHaveBeenCalledWith(301, expect.objectContaining({
          Location: 'https://fallback.com/'
        }));
      });
    });
  });
});
