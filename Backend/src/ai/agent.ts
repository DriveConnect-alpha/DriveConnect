/**
 * AI Agent com LangChain — Orquestra tools e chamadas à IA para atender requisições complexas.
 * Padrão: Detecção de intenção + extração de parâmetros + sugestão de ações.
 */

import 'dotenv/config';
import { ChatOpenAI } from '@langchain/openai';
import {
  checkRateLimit,
  validateAndSanitizeInput,
  logSecurityEvent,
  detectPromptInjection,
} from './security.js';
import { tool } from '@langchain/core/tools';
import { z } from 'zod';
import { query } from '../db/index.js';
import { answerWhatsAppMessage } from './rag.js';
import {
  toolListarFiliais,
  toolListarCarrosDisponiveis,
  toolValidarDisponibilidade,
  toolCriarReserva,
  toolObterReserva,
  toolObterFotosVeiculo,
  toolRegistrarCliente,
  TOOLS_MAP,
  type ToolResult,
} from './tools.js';

export type HistoryMessage = {
  role: 'user' | 'assistant';
  content: string;
};

type AgentOptions = {
  history?: HistoryMessage[];
  clienteId?: string;
  telefone?: string;
};

// ──────────────────────────────────────────────────────
// LOGGING E AUDITORIA
// ──────────────────────────────────────────────────────

interface AuditLog {
  timestamp: string;
  telefone?: string;
  cliente_id?: string;
  intencao: string;
  tools_chamadas: string[];
  resposta_final: string;
  sucesso: boolean;
  erro?: string;
}

const auditLogs: AuditLog[] = [];

function registrarAudit(log: AuditLog): void {
  auditLogs.push(log);
  console.log(`[AUDIT] ${log.timestamp} | ${log.intencao} | Tools: ${log.tools_chamadas.join(', ')}`);
}

export function obterAudits(limite = 100): AuditLog[] {
  return auditLogs.slice(-limite);
}

// ──────────────────────────────────────────────────────
// DETECÇÃO DE INTENÇÃO
// ──────────────────────────────────────────────────────

export type Intenao = 
  | 'LISTAR_FILIAIS'
  | 'LISTAR_CARROS'
  | 'COTACAO'
  | 'CRIAR_RESERVA'
  | 'RASTREAR_RESERVA'
  | 'VER_FOTOS'
  | 'REGISTRAR_CLIENTE'
  | 'SOBRE_DRIVE_CONNECT'
  | 'GENERICO';

function detectarIntencao(texto: string): Intenao {
  const t = (texto || '').toLowerCase();

  if (t.match(/\bfilial\b|\bfiliais\b|\bunidade\b|\bunidades\b|local(?:ização|izacao)?|endereço|endereco|onde fica|onde estão|onde estao/)) {
    return 'LISTAR_FILIAIS';
  }

  if (t.match(/carro(?:s)?|veículo(?:s)?|veiculo(?:s)?|modelo(?:s)?|categoria(?:s)?|opção(?:ões)?|opcao(?:es)?|qual(?:is)?|disponível(?:eis)?|disponivel(?:eis)?|frota/)) {
    if (t.match(/reserv|alugar|locação|locacao|booking/)) {
      return 'CRIAR_RESERVA';
    }
    return 'LISTAR_CARROS';
  }

  if (t.match(/preço|preco|valor|cust|cotação|cotacao|quanto/)) {
    return 'COTACAO';
  }

  if (t.match(/reserv|pedido|booking|minha|status|acompanhar|rastrear/)) {
    return 'RASTREAR_RESERVA';
  }

  if (t.match(/foto|imagem|foto|picture|mostrar|ver|enviar|compartilhar|compartilha|fotos|imagens/)) {
    return 'VER_FOTOS';
  }

  if (t.match(/cpf|email|registr|cadastr|novo|cliente|conta/)) {
    return 'REGISTRAR_CLIENTE';
  }

  if (t.match(/o que é|o que e|quem é|quem e|sobre|servi[cç]o|atendimento|qualidade|mercado|tempo de mercado|confiável|bom|empresa|drive connect/)) {
    return 'SOBRE_DRIVE_CONNECT';
  }

  return 'GENERICO';
}

// ──────────────────────────────────────────────────────
// EXTRATOR DE PARÂMETROS
// ──────────────────────────────────────────────────────

export interface ParametrosExtraidos {
  filial_id?: string;
  filial_ref?: string;
  categoria?: string;
  data_inicio?: string;
  data_fim?: string;
  cliente_id?: string;
  veiculo_id?: string;
  veiculo_ref?: string;
  reserva_id?: string;
  nome?: string;
  email?: string;
  cpf?: string;
  telefone?: string;
}

function responderSobreDriveConnect(): string {
  return 'A Drive Connect é uma locadora de veículos com atendimento rápido e humano via WhatsApp. A gente te ajuda com cotação, reserva, disponibilidade de carros, filiais e suporte durante a locação. Se quiser, posso te mostrar as filiais, os carros disponíveis ou já iniciar uma reserva.';
}

function responderDuvidaEmpresa(texto: string): string {
  const t = (texto || '').toLowerCase();

  if (t.includes('mercado') || t.includes('tempo')) {
    return 'Eu não tenho aqui a confirmação exata de há quanto tempo a Drive Connect está no mercado. O que eu posso te dizer com segurança é que o atendimento é focado em rapidez, clareza e suporte humano via WhatsApp. Se quiser, posso te mostrar as filiais e os carros disponíveis para você conhecer melhor a operação.';
  }

  if (t.includes('bom') || t.includes('qualidade') || t.includes('servi') || t.includes('atendimento') || t.includes('confiável')) {
    return 'A ideia da Drive Connect é oferecer um atendimento rápido e humano, com suporte durante a locação e informações claras sobre filiais, carros e reservas. Se você quiser avaliar melhor, posso te mostrar as filiais e os veículos disponíveis agora.';
  }

  return responderSobreDriveConnect();
}

type DecisaoIA = {
  intencao: Intenao;
  parametros: Partial<ParametrosExtraidos>;
  motivo?: string;
};

function extrairTextoDaResposta(resposta: unknown): string {
  if (typeof resposta === 'string') return resposta;

  if (Array.isArray(resposta)) {
    return resposta
      .map((item) => {
        if (typeof item === 'string') return item;
        if (item && typeof item === 'object' && 'text' in item) {
          return String((item as { text?: unknown }).text || '');
        }
        return '';
      })
      .join('');
  }

  if (resposta && typeof resposta === 'object' && 'content' in resposta) {
    return extrairTextoDaResposta((resposta as { content?: unknown }).content);
  }

  return String(resposta || '');
}

function extrairJsonDeTexto(texto: string): string | null {
  const clean = (texto || '').trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '');
  const match = clean.match(/\{[\s\S]*\}/);
  return match ? match[0] : null;
}

function normalizarIntencao(valor: unknown): Intenao {
  const intencao = String(valor || '').toUpperCase().trim();
  const validas: Intenao[] = [
    'LISTAR_FILIAIS',
    'LISTAR_CARROS',
    'COTACAO',
    'CRIAR_RESERVA',
    'RASTREAR_RESERVA',
    'VER_FOTOS',
    'REGISTRAR_CLIENTE',
    'SOBRE_DRIVE_CONNECT',
    'GENERICO',
  ];

  return validas.includes(intencao as Intenao) ? (intencao as Intenao) : 'GENERICO';
}

function formatarHistoricoParaRouter(history: HistoryMessage[]): string {
  if (!history || history.length === 0) return 'Sem histórico.';

  return history
    .slice(-8)
    .map((m) => `${m.role === 'assistant' ? 'Atendente' : 'Cliente'}: ${String(m.content || '').trim()}`)
    .filter(Boolean)
    .join('\n');
}

function normalizarTextoBusca(texto: string): string {
  return (texto || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/gi, ' ')
    .replace(/\b(?:r|rs|reais|dia|diaria|diario|por|foto|fotos|imagem|imagens|do|da|de|dos|das|o|a|um|uma|esse|essa|ai|aí)\b/g, ' ')
    .trim();
}

async function resolverIntencaoComIA(
  mensagem: string,
  historico: HistoryMessage[],
): Promise<DecisaoIA> {
  const prompt = `Você é um planejador flexível de atendimento da Drive Connect.
Seu objetivo é decidir, com bom senso, se a mensagem precisa de uma tool ou se pode ser respondida diretamente.

Se a mensagem for conversa natural, dúvida aberta, explicação, comparação, elogio, opinião ou pergunta institucional, prefira GENERICO.
Use tool apenas quando houver necessidade real de consultar dado estruturado.
Se houver incerteza, prefira GENERICO.

Intenções válidas:
- LISTAR_FILIAIS
- LISTAR_CARROS
- COTACAO
- CRIAR_RESERVA
- RASTREAR_RESERVA
- VER_FOTOS
- REGISTRAR_CLIENTE
- SOBRE_DRIVE_CONNECT
- GENERICO

Responda somente com JSON válido e neste formato:
{"intencao":"GENERICO","parametros":{},"motivo":"breve explicação"}

Histórico recente:
${formatarHistoricoParaRouter(historico)}

Mensagem do cliente:
${mensagem}`;

  const resposta = await agentConfig.model.invoke(prompt);
  const texto = extrairTextoDaResposta(resposta);
  const jsonTexto = extrairJsonDeTexto(texto);

  if (!jsonTexto) {
    throw new Error(`Roteador IA sem JSON válido: ${texto}`);
  }

  const parsed = JSON.parse(jsonTexto) as {
    intencao?: unknown;
    parametros?: Record<string, unknown>;
    motivo?: unknown;
  };

  return {
    intencao: normalizarIntencao(parsed.intencao),
    parametros: (parsed.parametros || {}) as Partial<ParametrosExtraidos>,
    motivo: typeof parsed.motivo === 'string' ? parsed.motivo : undefined,
  };
}

function pareceReferenciaVeiculo(texto: string): boolean {
  const t = (texto || '').trim();
  if (!t) return false;

  if (/^[A-Z]{3}\d[A-Z0-9]\d{2}$/i.test(t.replace(/\s+/g, ''))) return true;
  if (/^[A-Z]{3}-?\d{4}$/i.test(t.replace(/\s+/g, ''))) return true;
  if (/\b[a-z0-9]+\s+[a-z0-9]+\b/i.test(t) && t.length <= 40) return true;

  return false;
}

async function resolverVeiculoPorReferencia(referencia: string): Promise<{ id: string; placa: string; modelo: string } | null> {
  const semPreco = (referencia || '')
    .replace(/r\$\s*\d+[\d.,]*/gi, ' ')
    .replace(/\d+[\d.,]*/g, ' ')
    .replace(/\/dia|por\s+dia|diária|diaria/gi, ' ')
    .replace(/foto(s)?\s+(do|da|de|dos|das)\s+/gi, ' ');

  const termo = normalizarTextoBusca(semPreco);

  if (!termo) return null;

  const tokens = termo.split(/\s+/).filter((token) => token.length > 1);
  const result = await query(
    `SELECT v.id, v.placa, m.nome AS modelo, m.marca
     FROM veiculo v
     JOIN modelo m ON m.id = v.modelo_id
     WHERE v.deletado_em IS NULL
     ORDER BY v.id DESC
     LIMIT 200`,
  );

  const candidatos = result.rows.map((row) => ({
    id: String(row.id),
    placa: String(row.placa || ''),
    modelo: `${row.marca || ''} ${row.modelo || ''}`.trim(),
  }));

  const pontuado = candidatos
    .map((item) => {
      const alvo = normalizarTextoBusca(`${item.placa} ${item.modelo}`);
      const score = tokens.reduce((total, token) => total + (alvo.includes(token) ? 1 : 0), 0);
      const matchExato = alvo === termo ? 3 : 0;
      return { item, score: score + matchExato };
    })
    .filter((candidate) => candidate.score > 0)
    .sort((a, b) => b.score - a.score);

  const encontrado = pontuado[0]?.item || null;

  if (encontrado) {
    return encontrado;
  }

  const porModeloUnico = candidatos.find((item) => {
    const alvo = normalizarTextoBusca(`${item.placa} ${item.modelo}`);
    return tokens.some((token) => alvo.includes(token));
  });

  return porModeloUnico || null;
}

function extrairParametros(texto: string, intenao: Intenao): ParametrosExtraidos {
  const params: ParametrosExtraidos = {};

  // Datas (DD/MM/YYYY ou em português: "15 de maio")
  const dataMatch = texto.match(/(\d{1,2})\/(\d{1,2})\/(\d{4})/g);
  if (dataMatch && dataMatch.length >= 1 && dataMatch[0]) {
    const [dia, mes, ano] = dataMatch[0].split('/');
    params.data_inicio = `${ano}-${mes}-${dia}`;
  }
  if (dataMatch && dataMatch.length >= 2 && dataMatch[1]) {
    const [dia, mes, ano] = dataMatch[1].split('/');
    params.data_fim = `${ano}-${mes}-${dia}`;
  }

  // Categoria
  const categorias = ['SUV', 'Sedan', 'Econômico', 'Premium', 'Compacto', 'Utilitário'];
  for (const cat of categorias) {
    if (texto.toLowerCase().includes(cat.toLowerCase())) {
      params.categoria = cat;
      break;
    }
  }

  // CPF
  const cpfMatch = texto.match(/(\d{3})\.(\d{3})\.(\d{3})-(\d{2})/);
  if (cpfMatch) {
    params.cpf = cpfMatch[0];
  }

  // Email
  const emailMatch = texto.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/);
  if (emailMatch) {
    params.email = emailMatch[0];
  }

  // Nome (se for registrar, pegue "Meu nome é..."
  const nomeMatch = texto.match(/(?:nome|chamo|sou)\s+([A-Za-zÀ-ÿ\s]+?)(?:\.|,|$)/i);
  if (nomeMatch && nomeMatch[1]) {
    params.nome = nomeMatch[1].trim();
  }

  return params;
}

// ──────────────────────────────────────────────────────
// CRIAÇÃO DO AGENT COM TOOLS
// ──────────────────────────────────────────────────────

const langchainTools = [
  tool(
    async (input: any) => {
      const result = await toolListarFiliais();
      return JSON.stringify(result);
    },
    {
      name: 'listar_filiais',
      description:
        'Lista todas as filiais ativas com endereço, cidade e UF. Use quando cliente perguntar sobre unidades ou locais.',
      schema: z.object({}),
    },
  ),

  tool(
    async (input: any) => {
      const result = await toolListarCarrosDisponiveis(input);
      return JSON.stringify(result);
    },
    {
      name: 'listar_carros_disponiveis',
      description:
        'Lista carros disponíveis. Retorna APENAS veículos realmente disponíveis (sem conflitos de reserva). Parâmetros: filial_id, categoria, data_inicio, data_fim (YYYY-MM-DD).',
      schema: z.object({
        filial_id: z.string().optional().describe('UUID da filial'),
        categoria: z.string().optional().describe('Econômico, SUV, Sedan, Premium, etc'),
        data_inicio: z.string().optional().describe('YYYY-MM-DD'),
        data_fim: z.string().optional().describe('YYYY-MM-DD'),
      }),
    },
  ),

  tool(
    async (input: any) => {
      const result = await toolValidarDisponibilidade(input);
      return JSON.stringify(result);
    },
    {
      name: 'validar_disponibilidade',
      description:
        'Valida se um veículo específico está disponível para um período. Use ANTES de criar reserva.',
      schema: z.object({
        veiculo_id: z.string().describe('UUID do veículo'),
        data_inicio: z.string().describe('YYYY-MM-DD'),
        data_fim: z.string().describe('YYYY-MM-DD'),
      }),
    },
  ),

  tool(
    async (input: any) => {
      const result = await toolCriarReserva(input);
      return JSON.stringify(result);
    },
    {
      name: 'criar_reserva',
      description:
        'Cria uma nova reserva e gera link de pagamento. Validação automática. Parâmetros obrigatórios: cliente_id, veiculo_id, filial_retirada_id, data_inicio, data_fim.',
      schema: z.object({
        cliente_id: z.string().describe('UUID do cliente'),
        veiculo_id: z.string().describe('UUID do veículo'),
        filial_retirada_id: z.string().describe('UUID da filial de retirada'),
        filial_devolucao_id: z.string().optional().describe('UUID da filial de devolução'),
        data_inicio: z.string().describe('YYYY-MM-DD'),
        data_fim: z.string().describe('YYYY-MM-DD'),
        plano_seguro_id: z.string().optional(),
        metodo_pagamento: z.string().optional().describe('INFINITEPAY ou DINHEIRO'),
      }),
    },
  ),

  tool(
    async (input: any) => {
      const result = await toolObterReserva(input.reserva_id);
      return JSON.stringify(result);
    },
    {
      name: 'obter_reserva',
      description: 'Obtém status e detalhes de uma reserva existente.',
      schema: z.object({
        reserva_id: z.string().describe('UUID da reserva'),
      }),
    },
  ),

  tool(
    async (input: any) => {
      const result = await toolRegistrarCliente(input);
      return JSON.stringify(result);
    },
    {
      name: 'registrar_cliente',
      description:
        'Registra um novo cliente. Use quando cliente fornecer nome, email e CPF. Parâmetros obrigatórios: nome_completo, email, cpf.',
      schema: z.object({
        nome_completo: z.string().describe('Nome completo'),
        email: z.string().describe('Email'),
        cpf: z.string().describe('CPF (XXX.XXX.XXX-XX ou 11 dígitos)'),
        telefone: z.string().optional(),
      }),
    },
  ),
];

// ──────────────────────────────────────────────────────
// SYSTEM PROMPT (para referência)
// ──────────────────────────────────────────────────────

const systemPrompt = `Você é o assistente de atendimento da Drive Connect, locadora de veículos.
Objetivo: ajudar clientes com cotações, reservas, rastreamento e suporte via WhatsApp.
Estilo: cordial, natural e acolhedor, sem soar engessado. Seja direto quando necessário, mas com um toque humano. Evite markdown, use 1–3 parágrafos e, quando fizer sentido, uma saudação breve.

Diretrizes:
1. Use as tools disponíveis para obter informações reais (filiais, carros, preços).
2. Nunca invente dados de disponibilidade ou preço.
3. Para reserva: valide disponibilidade ANTES de criar.
4. Mantenha histórico de conversa.
5. Se faltarem dados, faça perguntas simples.
6. Sempre confirme antes de ação irreversível.

Nunca ignore erros de validação — reporte ao cliente e ofereça alternativa.`;

// ──────────────────────────────────────────────────────
// AGENT (SIMPLIFIED — DIRECT TOOL CALLING)
// ──────────────────────────────────────────────────────

// Agent simples baseado em intenção detecção + tool chamadas diretas
const agentConfig = {
  model: new ChatOpenAI({
    modelName: process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini',
    temperature: 0.3,
    openAIApiKey: process.env.OPENAI_API_KEY || '',
    maxTokens: 500,
    timeout: 10000,
  }),
  verbose: process.env.NODE_ENV === 'development',
};


// ──────────────────────────────────────────────────────
// FUNÇÃO PRINCIPAL: ATENDER CLIENTE COM AGENT
// ──────────────────────────────────────────────────────

export async function atenderClienteComAgent(
  mensagem: string,
  opcoes: AgentOptions = {},
): Promise<{
  resposta: string;
  intencao: Intenao;
  tools_usadas: string[];
  cliente_id?: string;
  fotos?: string[]; // URLs de fotos para enviar via WhatsApp
  auditoria: AuditLog;
}> {
  const timestamp = new Date().toISOString();
  const telefone = opcoes.telefone || 'unknown';

  // ──────────────────────────────────────────────────────
  // 1. VALIDAÇÃO DE SEGURANÇA
  // ──────────────────────────────────────────────────────

  // 1a. Rate limiting
  const rateLimitCheck = checkRateLimit(telefone);
  if (!rateLimitCheck.allowed) {
    void logSecurityEvent({
      tipo: 'SUSPICIOUS',
      telefone,
      cliente_id: opcoes.clienteId || null,
      descricao: rateLimitCheck.reason || 'Rate limit excedido',
      severity: 'MEDIUM',
    });

    return {
      resposta:
        'Você está enviando muitas mensagens. Por favor, aguarde um momento e tente novamente.',
      intencao: 'GENERICO' as Intenao,
      tools_usadas: [],
      cliente_id: opcoes.clienteId || undefined,
      auditoria: {
        timestamp,
        telefone: telefone || undefined,
        cliente_id: opcoes.clienteId || undefined,
        intencao: 'BLOCKED_BY_RATE_LIMIT',
        tools_chamadas: [],
        resposta_final: 'Rate limited',
        sucesso: false,
        erro: 'Rate limit excedido',
      },
    };
  }

  // 1b. Validar e sanitizar input
  const validacao = validateAndSanitizeInput(mensagem, telefone);
  if (!validacao.valid) {
    void logSecurityEvent({
      tipo: 'INJECTION_ATTEMPT',
      telefone,
      cliente_id: opcoes.clienteId || null,
      descricao: validacao.reason || 'Input inválido',
      severity: validacao.injection_detected ? 'HIGH' : 'MEDIUM',
    });

    return {
      resposta: 'Sua mensagem contém caracteres ou padrões não permitidos. Por favor, tente novamente com uma mensagem mais simples.',
      intencao: 'GENERICO',
      tools_usadas: [],
      cliente_id: opcoes.clienteId,
      auditoria: {
        timestamp,
        telefone,
        cliente_id: opcoes.clienteId,
        intencao: 'VALIDATION_FAILED',
        tools_chamadas: [],
        resposta_final: 'Invalid input',
        sucesso: false,
        erro: validacao.reason,
      },
    };
  }

  const mensagemSanitizada = validacao.sanitized;

  // ──────────────────────────────────────────────────────
  // 2. DETECÇÃO DE INTENÇÃO E PARÂMETROS
  // ──────────────────────────────────────────────────────

  let intenao: Intenao = 'GENERICO';
  let params: Partial<ParametrosExtraidos> = {};
  const toolsUsadas: string[] = [];

  try {
    // 1. Armazenar histórico (simplificado)
    // Mantém histórico em memória para contexto
    const historico = opcoes.history || [];

    try {
      const decisao = await resolverIntencaoComIA(mensagemSanitizada, historico);
      intenao = decisao.intencao;
      params = {
        ...extrairParametros(mensagemSanitizada, decisao.intencao),
        ...decisao.parametros,
      };
    } catch (routerError) {
      intenao = detectarIntencao(mensagemSanitizada);
      params = extrairParametros(mensagemSanitizada, intenao);
      void logSecurityEvent({
        tipo: 'SUSPICIOUS',
        telefone,
        cliente_id: opcoes.clienteId || null,
        descricao: `Router IA falhou, usando fallback: ${routerError instanceof Error ? routerError.message : 'desconhecido'}`,
        severity: 'LOW',
      });
    }

    // 2. Compilar contexto
    const contexto = [
      `Intenção detectada: ${intenao}`,
      opcoes.clienteId ? `Cliente ID: ${opcoes.clienteId}` : null,
      opcoes.telefone ? `Telefone: ${opcoes.telefone}` : null,
      Object.entries(params).length > 0
        ? `Parâmetros extraídos: ${JSON.stringify(params)}`
        : null,
    ]
      .filter(Boolean)
      .join('\n');

    // 3. Gerar resposta baseada em intenção
    let respostaFinal = '';
    let fotosParaEnviar: string[] = [];

    const textoPedeFoto = /\bfoto(s)?\b|\bimagem(ns)?\b|\bver\s+a\s+foto\b|\bmostrar\s+a\s+foto\b/i.test(mensagemSanitizada);

    if (textoPedeFoto) {
      intenao = 'VER_FOTOS';
    }

    if (intenao === 'VER_FOTOS' && !params.veiculo_id) {
      const referenciaVeiculo = await resolverVeiculoPorReferencia(String(params.veiculo_ref || mensagemSanitizada));
      if (referenciaVeiculo) {
        params.veiculo_id = referenciaVeiculo.id;
      } else if (pareceReferenciaVeiculo(String(params.veiculo_ref || mensagemSanitizada))) {
        respostaFinal = 'Achei que você quer ver uma foto, mas ainda não consegui identificar o veículo com segurança. Se puder, me mande a placa ou o nome exato do modelo, por favor.';
      }
    }

    if (intenao === 'LISTAR_CARROS' && !params.filial_id) {
      const referenciaFilial = normalizarTextoBusca(String(params.filial_ref || mensagemSanitizada));
      const filialRes = await query(
        `SELECT id, nome, cidade, uf
         FROM filial
         WHERE deletado_em IS NULL AND ativo = TRUE
         ORDER BY cidade, nome`,
      );

      const tokens = referenciaFilial.split(/\s+/).filter((token) => token.length > 1);
      const filialEncontrada = filialRes.rows
        .map((row) => ({
          id: String(row.id),
          nome: String(row.nome || ''),
          cidade: String(row.cidade || ''),
          uf: String(row.uf || ''),
        }))
        .find((filial) => {
          const alvo = normalizarTextoBusca(`${filial.nome} ${filial.cidade} ${filial.uf}`);
          return tokens.some((token) => alvo.includes(token));
        });

      if (filialEncontrada) {
        params.filial_id = filialEncontrada.id;
      }
    }
    
    switch (intenao) {
      case 'LISTAR_FILIAIS': {
        const result = await toolListarFiliais();
        if (result.success && result.data) {
          const filiais = result.data;
          if (filiais.length > 0) {
            respostaFinal = `Encontrei ${result.data.length} filial(is):\n${filiais.map(f => `• ${f.nome} - ${f.endereco}`).join('\n')}`;
          } else {
            respostaFinal = await answerWhatsAppMessage('Quais são as filiais da Drive Connect?', { history: historico });
          }
          toolsUsadas.push('listar_filiais');
        } else {
          respostaFinal = await answerWhatsAppMessage('Quais são as filiais da Drive Connect?', { history: historico });
        }
        break;
      }

      case 'LISTAR_CARROS': {
        if (!params.filial_id) {
          const filiaisResult = await toolListarFiliais();
          if (filiaisResult.success && filiaisResult.data && filiaisResult.data.length > 0) {
            const filiais = filiaisResult.data;
            respostaFinal = `Claro — me diga de qual filial você quer ver os carros. Aqui estão todas as filiais ativas:\n${filiais.map((f) => `• ${f.nome} - ${f.endereco}`).join('\n')}`;
          } else {
            respostaFinal = 'Claro — me diga de qual filial você quer ver os carros. Não consegui carregar a lista de filiais agora, mas posso tentar de novo se você quiser.';
          }
          toolsUsadas.push('listar_filiais');
          break;
        }

        const result = await toolListarCarrosDisponiveis(params);
        if (result.success && result.data && result.data.length > 0) {
          const carros = result.data;
          respostaFinal = `Encontrei ${result.data.length} carro(s) disponível(is):\n${carros.map((c: any) => `• ${c.modelo} ${c.marca} - R$ ${c.preco_diaria}/dia`).join('\n')}\n\nDigite "foto do [modelo]" para ver a foto de algum.`;
          toolsUsadas.push('listar_carros_disponiveis');
        } else {
          respostaFinal = await answerWhatsAppMessage(mensagemSanitizada, { history: historico });
        }
        break;
      }

      case 'CRIAR_RESERVA': {
        // Fluxo de criação de reserva
        respostaFinal = 'Para criar uma reserva, preciso de alguns dados: período (datas de retirada e devolução), categoria de carro preferida e seus dados (nome, CPF, email). Pode fornecer essas informações?';
        break;
      }

      case 'RASTREAR_RESERVA': {
        if (params.reserva_id) {
          const result = await toolObterReserva(params.reserva_id);
          if (result.success && result.data) {
            respostaFinal = `Status da sua reserva #${result.data.id}:\n• Veículo: ${result.data.modelo}\n• Período: ${result.data.data_inicio} a ${result.data.data_fim}\n• Valor: R$ ${result.data.valor_total}\n• Status: ${result.data.status}`;
            toolsUsadas.push('obter_reserva');
          } else {
            respostaFinal = 'Não consegui encontrar essa reserva. Pode verificar o ID?';
          }
        } else {
          respostaFinal = 'Qual é o ID da sua reserva? Você pode encontrar no email de confirmação.';
        }
        break;
      }

      case 'VER_FOTOS': {
        if (!params.veiculo_id && respostaFinal) {
          break;
        }

        if (params.veiculo_id) {
          const result = await toolObterFotosVeiculo(params.veiculo_id);
          if (result.success && result.data) {
            // Enviar apenas a foto principal
            const fotoPrincipal = result.data.fotos.find((f: any) => f.principal) || result.data.fotos[0];
            if (fotoPrincipal) {
              fotosParaEnviar = [fotoPrincipal.url]; // Apenas 1 foto
            }
            respostaFinal = `📸 Aqui está a foto do ${result.data.modelo} (${result.data.placa})`;
            toolsUsadas.push('obter_fotos_veiculo');
          } else {
            respostaFinal = result.error || 'Desculpe, não consegui acessar a foto deste veículo.';
          }
        } else {
          respostaFinal = 'Qual veículo você gostaria de ver a foto? Pode me passar o modelo ou a placa do carro.';
        }
        break;
      }

      case 'REGISTRAR_CLIENTE': {
        respostaFinal = 'Ótimo! Para me registrar, preciso de: nome completo, email e CPF. Pode fornecer?';
        break;
      }

      case 'SOBRE_DRIVE_CONNECT': {
        try {
          respostaFinal = await answerWhatsAppMessage(mensagemSanitizada, { history: historico });
          if (!respostaFinal || respostaFinal.length < 20) {
            respostaFinal = responderDuvidaEmpresa(mensagemSanitizada);
          }
        } catch {
          respostaFinal = responderDuvidaEmpresa(mensagemSanitizada);
        }
        break;
      }

      default:
        try {
          respostaFinal = await answerWhatsAppMessage(mensagemSanitizada, { history: historico });
        } catch {
          respostaFinal = 'Claro, posso te ajudar com filiais, carros disponíveis, reservas e dúvidas sobre a Drive Connect. Se quiser, me diga o que você procura e eu sigo com você.';
        }
    }

    // Cleanup: remover markdown e logs desnecessários
    respostaFinal = respostaFinal
      .replace(/\*\*/g, '') // Remover **negrito**
      .replace(/```[\s\S]*?```/g, '') // Remover code blocks
      .replace(/\[(?:TOOL_CALLS|LOG)[\s\S]*?\]/g, ''); // Remover logs internos

    // 4. Registrar auditoria
    const audit: AuditLog = {
      timestamp,
      telefone: opcoes.telefone,
      cliente_id: opcoes.clienteId,
      intencao: intenao,
      tools_chamadas: toolsUsadas,
      resposta_final: respostaFinal.slice(0, 200),
      sucesso: true,
    };

    registrarAudit(audit);

    return {
      resposta: respostaFinal,
      intencao: intenao,
      tools_usadas: toolsUsadas,
      cliente_id: opcoes.clienteId,
      fotos: fotosParaEnviar.length > 0 ? fotosParaEnviar : undefined,
      auditoria: audit,
    };
  } catch (err) {
    const erro = err instanceof Error ? err.message : 'Erro desconhecido';

    const audit: AuditLog = {
      timestamp,
      telefone: opcoes.telefone,
      cliente_id: opcoes.clienteId,
      intencao: intenao,
      tools_chamadas: toolsUsadas,
      resposta_final: 'Erro ao processar',
      sucesso: false,
      erro,
    };

    registrarAudit(audit);

    return {
      resposta: `Desculpe, tive um problema ao processar sua solicitação. Pode tentar novamente em instantes?`,
      intencao: intenao,
      tools_usadas: toolsUsadas,
      cliente_id: opcoes.clienteId,
      auditoria: audit,
    };
  }
}

// ──────────────────────────────────────────────────────
// EXPORTS
// ──────────────────────────────────────────────────────

export { detectarIntencao, extrairParametros };
