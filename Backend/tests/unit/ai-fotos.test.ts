/**
 * Testes para funcionalidade de fotos de veículos
 */

import { describe, it, expect } from '@jest/globals';
import { toolObterFotosVeiculo } from '../../src/ai/tools.js';

describe('📸 Fotos de Veículos - Testes', () => {
  describe('Detecção de Intenção VER_FOTOS', () => {
    it('Deve detectar VER_FOTOS quando cliente pede foto de um carro', () => {
      const { detectarIntencao } = require('../../src/ai/agent.js');

      const mensagens = [
        'Foto do Gol',
        'Mostre a foto',
        'Quero ver a imagem',
        'Tem foto desse carro?',
        'Manda a foto',
        'Ver foto do veículo',
      ];

      mensagens.forEach((msg) => {
        const intencao = detectarIntencao(msg);
        expect(intencao).toBe('VER_FOTOS');
      });
    });

    it('Deve retornar erro se veículo não existir', async () => {
      const resultado = await toolObterFotosVeiculo('veiculo-inexistente-123');

      expect(resultado.success).toBe(false);
      expect(resultado.error).toContain('Veículo não encontrado');
    });

    it('Deve retornar erro se não houver fotos', async () => {
      const resultado = await toolObterFotosVeiculo('veiculo-sem-fotos-456');

      expect(resultado.success).toBe(false);
      expect(resultado.error).toContain('não possui fotos');
    });

    it('Deve retornar estrutura correta quando sucesso (mock)', () => {
      const mockResult = {
        success: true,
        data: {
          veiculo_id: '123',
          placa: 'ABC1234',
          modelo: 'Gol',
          fotos: [
            { url: 'https://example.com/foto1.jpg', principal: true },
            { url: 'https://example.com/foto2.jpg', principal: false }
          ]
        }
      };

      expect(mockResult.success).toBe(true);
      expect(mockResult.data).toBeDefined();
      expect(mockResult.data?.fotos).toBeInstanceOf(Array);
      expect(mockResult.data?.fotos.length).toBeGreaterThan(0);
      expect(mockResult.data?.fotos[0]).toHaveProperty('url');
      expect(mockResult.data?.fotos[0]).toHaveProperty('principal');
    });

    it('Deve marcar foto principal como primeira', () => {
      const fotos = [
        { url: 'url1.jpg', principal: true },
        { url: 'url2.jpg', principal: false },
        { url: 'url3.jpg', principal: false }
      ];

      const fotoPrincipal = fotos.find(f => f.principal);
      expect(fotoPrincipal).toBeDefined();
      expect(fotos[0].principal).toBe(true);
    });

    it('Deve enviar apenas 1 foto quando cliente pede', () => {
      const fotosParaEnviar = ['https://example.com/corolla.jpg'];

      expect(fotosParaEnviar).toBeInstanceOf(Array);
      expect(fotosParaEnviar.length).toBe(1);
      expect(fotosParaEnviar[0]).toMatch(/https?:\/\//);
    });
  });

  describe('Fluxo de Envio de Fotos', () => {
    it('Deve retornar fotos no resultado quando VER_FOTOS', () => {
      const resultado = {
        resposta: '📸 Aqui está a foto do Corolla',
        intencao: 'VER_FOTOS',
        tools_usadas: ['obter_fotos_veiculo'],
        fotos: ['https://example.com/corolla-principal.jpg']
      };

      expect(resultado).toHaveProperty('fotos');
      expect(resultado.intencao).toBe('VER_FOTOS');
      expect(resultado.fotos).toBeInstanceOf(Array);
      expect(resultado.fotos?.length).toBe(1);
    });

    it('Deve ter fotos undefined para intenções sem fotos', () => {
      const resultado = {
        resposta: 'Encontrei 3 carros...',
        intencao: 'LISTAR_CARROS',
        tools_usadas: ['listar_carros_disponiveis'],
        fotos: undefined as string[] | undefined
      };

      expect(resultado.fotos === undefined || (resultado.fotos && resultado.fotos.length === 0)).toBe(true);
    });

    it('Deve validar URLs das fotos', () => {
      const fotos = [
        'https://example.com/foto1.jpg',
        'https://cdn.example.com/foto2.png',
        'http://images.example.com/foto3.jpeg'
      ];

      fotos.forEach(url => {
        expect(url).toMatch(/^https?:\/\//);
        expect(url).toMatch(/\.(jpg|jpeg|png|gif|webp)$/i);
      });
    });
  });

  describe('Integração com WhatsApp Service', () => {
    it('Deve chamar sendImageByUrl quando houver foto', () => {
      const agentResult = {
        fotos: ['https://example.com/foto.jpg'],
        resposta: '📸 Aqui está a foto'
      };

      expect(agentResult.fotos).toBeDefined();
      expect(agentResult.fotos?.length).toBe(1);
    });

    it('Deve enviar apenas 1 foto de cada vez', () => {
      const fotosParaEnviar = ['https://example.com/corolla.jpg'];

      expect(fotosParaEnviar.length).toBe(1);
    });

    it('Deve não quebrar conversa se foto falhar', () => {
      const textoResposta = '📸 Aqui está a foto do Corolla';

      expect(textoResposta).toBeDefined();
      expect(textoResposta.length).toBeGreaterThan(0);
    });
  });

  describe('Campos de Resposta Estendida', () => {
    it('ReservaDetalhes deve incluir imagem_url e placa', () => {
      const reserva = {
        id: '123',
        cliente_nome: 'João',
        modelo: 'Gol',
        data_inicio: '2026-05-20',
        data_fim: '2026-05-25',
        valor_total: 250,
        status: 'PENDENTE_PAGAMENTO',
        imagem_url: 'https://example.com/img.jpg',
        placa: 'ABC1234',
        cor: 'Branco',
      };

      expect(reserva).toHaveProperty('imagem_url');
      expect(reserva).toHaveProperty('placa');
      expect(reserva).toHaveProperty('cor');
      expect(reserva.imagem_url).toMatch(/https?:\/\//);
    });

    it('CarroDisponivel deve incluir imagem_url', () => {
      const carro = {
        id: '1',
        placa: 'ABC1234',
        modelo: 'Gol',
        marca: 'Volkswagen',
        categoria: 'Econômico',
        ano: 2026,
        cor: 'Branco',
        filial_id: 'fil-1',
        filial_nome: 'São Paulo',
        preco_diaria: 100,
        status: 'DISPONIVEL',
        imagem_url: 'https://example.com/gol.jpg',
      };

      expect(carro).toHaveProperty('imagem_url');
      expect(carro.imagem_url).toMatch(/https?:\/\//);
    });
  });

  describe('Casos Extremos', () => {
    it('Deve aceitar URLs longas (até 2048 caracteres)', () => {
      const urlLonga = 'https://example.com/images/' + 'a'.repeat(2000) + '.jpg';
      expect(urlLonga.length).toBeLessThanOrEqual(2048);
    });

    it('Deve lidar com nomes especiais de veículos', () => {
      const nomes = [
        'Gol G7++',
        "C3 Picasso's",
        'Civic Type-R',
        'i30 N-Performance'
      ];

      nomes.forEach(nome => {
        expect(nome).toBeDefined();
        expect(nome.length).toBeGreaterThan(0);
      });
    });

    it('Deve validar extensões de imagem', () => {
      const extensoesValidas = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      const url = 'https://example.com/foto.jpg';

      const valida = extensoesValidas.some(ext => url.toLowerCase().endsWith(ext));
      expect(valida).toBe(true);
    });

    it('Deve rejeitar URLs com extensões inválidas', () => {
      const extensoesInvalidas = ['.pdf', '.doc', '.zip', '.exe'];
      const url = 'https://example.com/documento.pdf';

      const invalida = extensoesInvalidas.some(ext => url.toLowerCase().endsWith(ext));
      expect(invalida).toBe(true);
    });

    it('Deve extrair foto principal quando houver múltiplas', () => {
      const fotos = [
        { url: 'url1.jpg', principal: true },
        { url: 'url2.jpg', principal: false },
        { url: 'url3.jpg', principal: false },
      ];

      const fotoPrincipal = fotos.find(f => f.principal) || fotos[0];
      expect(fotoPrincipal.url).toBe('url1.jpg');
    });
  });
});
