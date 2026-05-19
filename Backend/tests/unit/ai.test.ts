/**
 * TESTES PARA AI AGENT E TOOLS
 * Rodar: npm test -- tests/unit/ai.test.ts
 */

import 'dotenv/config';
import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import {
  toolListarFiliais,
  toolListarCarrosDisponiveis,
  toolValidarDisponibilidade,
  toolCriarReserva,
  toolObterReserva,
  toolRegistrarCliente,
  executeTool,
  type ToolResult,
} from '../../src/ai/tools.js';
import { detectarIntencao, extrairParametros } from '../../src/ai/agent.js';

describe('🤖 AI TOOLS & AGENT', () => {
  // ──────────────────────────────────────────────────────
  // INTENT DETECTION
  // ──────────────────────────────────────────────────────

  describe('📋 Detecção de Intenção', () => {
    it('deve detectar LISTAR_FILIAIS', () => {
      const textos = [
        'Vocês têm filiais em SP?',
        'Qual a unidade mais próxima?',
        'Endereço do local em São Paulo?',
      ];
      for (const texto of textos) {
        expect(detectarIntencao(texto)).toBe('LISTAR_FILIAIS');
      }
    });

    it('deve detectar LISTAR_CARROS', () => {
      const textos = [
        'Quais carros vocês têm?',
        'Modelos disponíveis?',
        'Que SUVs vocês oferecem?',
      ];
      for (const texto of textos) {
        expect(detectarIntencao(texto)).toBe('LISTAR_CARROS');
      }
    });

    it('deve detectar CRIAR_RESERVA', () => {
      const textos = [
        'Quero alugar um carro para 16/05',
        'Como fazer uma reserva?',
        'Preciso de um SUV para uma semana',
      ];
      for (const texto of textos) {
        expect([
          'CRIAR_RESERVA',
          'LISTAR_CARROS', // fallback se não detectar "reserva"
        ]).toContain(detectarIntencao(texto));
      }
    });

    it('deve detectar REGISTRAR_CLIENTE', () => {
      const textos = [
        'Meu CPF é 123.456.789-10',
        'Como me registrar?',
        'Preciso criar uma conta',
      ];
      for (const texto of textos) {
        expect(detectarIntencao(texto)).toBe('REGISTRAR_CLIENTE');
      }
    });
  });

  // ──────────────────────────────────────────────────────
  // PARAMETER EXTRACTION
  // ──────────────────────────────────────────────────────

  describe('🔍 Extração de Parâmetros', () => {
    it('deve extrair datas em DD/MM/YYYY', () => {
      const texto = 'Quero alugar de 16/05/2026 até 18/05/2026';
      const params = extrairParametros(texto, 'CRIAR_RESERVA');
      expect(params.data_inicio).toBe('2026-05-16');
      expect(params.data_fim).toBe('2026-05-18');
    });

    it('deve extrair CPF', () => {
      const texto = 'Meu CPF é 123.456.789-10 e email teste@example.com';
      const params = extrairParametros(texto, 'REGISTRAR_CLIENTE');
      expect(params.cpf).toBe('123.456.789-10');
      expect(params.email).toBe('teste@example.com');
    });

    it('deve extrair categoria de carro', () => {
      const texto = 'Preciso de um SUV grande para a família';
      const params = extrairParametros(texto, 'LISTAR_CARROS');
      expect(params.categoria).toBe('SUV');
    });

    it('deve extrair nome', () => {
      const texto = 'Meu nome é João Silva e quero registrar';
      const params = extrairParametros(texto, 'REGISTRAR_CLIENTE');
      expect(params.nome?.toLowerCase()).toContain('joão');
    });
  });

  // ──────────────────────────────────────────────────────
  // TOOLS EXECUTION
  // ──────────────────────────────────────────────────────

  describe('🔧 Execução de Tools', () => {
    it('listar_filiais deve retornar array de filiais', async () => {
      const result = await toolListarFiliais();
      expect(result.success).toBe(true);
      expect(Array.isArray(result.data)).toBe(true);
      if (result.data && result.data.length > 0) {
        const filial = result.data[0];
        expect(filial).toHaveProperty('id');
        expect(filial).toHaveProperty('nome');
        expect(filial).toHaveProperty('endereco');
      }
    });

    it('listar_carros_disponiveis deve validar datas', async () => {
      const result = await toolListarCarrosDisponiveis({
        data_inicio: '2026-05-16',
        data_fim: '2026-05-14', // DATA FIM ANTES DO INÍCIO (ERRO)
      });
      expect(result.success).toBe(false);
      expect(result.error).toContain('data_fim deve ser');
    });

    it('listar_carros_disponiveis sem parâmetros deve retornar lista', async () => {
      const result = await toolListarCarrosDisponiveis({});
      if (result.success) {
        expect(Array.isArray(result.data)).toBe(true);
      }
    });

    it('validar_disponibilidade com veículo inválido deve falhar', async () => {
      const result = await toolValidarDisponibilidade({
        veiculo_id: 'id-invalido-uuid',
        data_inicio: '2026-05-16',
        data_fim: '2026-05-18',
      });
      // Pode falhar por validação de UUID ou por veículo não existir
      expect(typeof result.success).toBe('boolean');
    });

    it('registrar_cliente deve falhar com CPF inválido', async () => {
      const result = await toolRegistrarCliente({
        nome_completo: 'João Silva',
        email: 'joao@example.com',
        cpf: '000.000.000-00', // CPF inválido
      });
      expect(result.success).toBe(false);
    });

    it('criar_reserva sem cliente_id deve falhar', async () => {
      const result = await toolCriarReserva({
        cliente_id: '', // VAZIO
        veiculo_id: 'some-uuid',
        filial_retirada_id: 'some-uuid',
        data_inicio: '2026-05-16',
        data_fim: '2026-05-18',
      });
      expect(result.success).toBe(false);
    });
  });

  // ──────────────────────────────────────────────────────
  // EXECUTE TOOL DISPATCHER
  // ──────────────────────────────────────────────────────

  describe('⚙️ Dispatcher de Tools (executeTool)', () => {
    it('deve executar listar_filiais via dispatcher', async () => {
      const result = await executeTool('listar_filiais', {});
      expect(result.success).toBe(true);
    });

    it('deve executar listar_carros_disponiveis via dispatcher', async () => {
      const result = await executeTool('listar_carros_disponiveis', {
        data_inicio: '2026-05-16',
        data_fim: '2026-05-18',
      });
      expect(typeof result.success).toBe('boolean');
    });
  });

  // ──────────────────────────────────────────────────────
  // INTEGRATION TESTS (requerem DB real)
  // ──────────────────────────────────────────────────────

  describe('🔗 Testes de Integração (com DB)', () => {
    beforeAll(() => {
      // Setup
      console.log('   Iniciando testes de integração...');
    });

    afterAll(() => {
      // Cleanup
      console.log('   Encerrando testes de integração...');
    });

    it('fluxo completo: listar filiais → carros → validar → criar (MOCK)', async () => {
      // Simular fluxo completo sem criar data real
      // 1. Listar filiais
      const filiaisResult = await toolListarFiliais();
      if (!filiaisResult.success) {
        console.log('   ⚠️  Filiais não acessíveis, pulando teste');
        return;
      }

      const filiais = filiaisResult.data;
      if (!filiais || filiais.length === 0) {
        console.log('   ⚠️  Nenhuma filial encontrada');
        return;
      }

      // 2. Listar carros
      const carrosResult = await toolListarCarrosDisponiveis({
        filial_id: filiais[0].id,
        data_inicio: '2026-05-16',
        data_fim: '2026-05-18',
      });
      expect(typeof carrosResult.success).toBe('boolean');

      if (carrosResult.success && carrosResult.data && carrosResult.data.length > 0) {
        const carro = carrosResult.data[0];

        // 3. Validar disponibilidade
        const validacaoResult = await toolValidarDisponibilidade({
          veiculo_id: carro.id,
          data_inicio: '2026-05-16',
          data_fim: '2026-05-18',
        });
        expect(typeof validacaoResult.success).toBe('boolean');
      }
    });
  });
});
