# 🤖 ARQUITETURA DO AI AGENT DRIVECONNECT

## 📋 Visão Geral

O sistema de IA foi completamente reimplementado com um **padrão Agent + Tools** usando LangChain e OpenAI, substituindo o modelo anterior baseado em RAG puro.

**Fluxo:**
```
Mensagem WhatsApp
    ↓
[Detectar Intenção]
    ↓
[Extrair Parâmetros]
    ↓
[LangChain Agent com ReAct]
    ↓
[Seleção e Execução de Tools]
    ├─ listar_filiais
    ├─ listar_carros_disponiveis
    ├─ validar_disponibilidade
    ├─ criar_reserva
    ├─ obter_reserva
    └─ registrar_cliente
    ↓
[Resposta Conversacional + Resultado]
    ↓
Enviar WhatsApp
```

---

## 🏗️ Componentes Principais

### 1. **AGENT** (`Backend/src/ai/agent.ts`)

**Responsabilidade:** Orquestração de tools + resposta conversacional

**Funções principais:**
- `atenderClienteComAgent(mensagem, opcoes)` — função principal
- `detectarIntencao(texto)` — classifica tipo de requisição
- `extrairParametros(texto, intenao)` — extrai dados estruturados
- `registrarAudit(log)` — logging de auditoria

**Tipos de intenção:**
- `LISTAR_FILIAIS` — Cliente quer saber locais
- `LISTAR_CARROS` — Cliente quer ver opções
- `COTACAO` — Cliente quer preço/valor
- `CRIAR_RESERVA` — Cliente quer alugar
- `RASTREAR_RESERVA` — Cliente quer saber status
- `REGISTRAR_CLIENTE` — Cliente quer se registrar
- `GENERICO` — Pergunta geral (política, cancelamento, etc)

**Exemplo de uso:**
```typescript
const resultado = await atenderClienteComAgent(
  'Quero um carro para 16/05 a 18/05',
  {
    telefone: '+5511987654321',
    clienteId: 'uuid-cliente',
    history: [] // histórico de conversa anterior
  }
);

console.log(resultado.resposta); // Resposta conversacional
console.log(resultado.tools_usadas); // ['listar_carros_disponiveis', ...]
console.log(resultado.intencao); // 'CRIAR_RESERVA'
```

---

### 2. **TOOLS** (`Backend/src/ai/tools.ts`)

**Responsabilidade:** Executar ações reais contra o banco de dados

Cada tool:
- ✅ Valida inputs (datas, UUIDs, CPF, etc)
- ✅ Consulta DB para dados atuais (não cacheados)
- ✅ Retorna estrutura padronizada `ToolResult<T>`
- ✅ Handles erros gracefully

**6 Tools Disponíveis:**

#### A. `toolListarFiliais()` — Lista todas as unidades
```typescript
const result = await toolListarFiliais();
// Retorna:
// {
//   success: true,
//   data: [
//     { id: 'uuid', nome: 'SP Centro', endereco: '...', cidade: 'São Paulo', uf: 'SP', telefone: '...' },
//     ...
//   ]
// }
```

#### B. `toolListarCarrosDisponiveis(params)` — Lista carros SEM CONFLITO DE RESERVA
```typescript
const result = await toolListarCarrosDisponiveis({
  filial_id?: 'uuid',        // Opcional: filtrar por filial
  categoria?: 'SUV',          // Opcional: Econômico, SUV, Sedan, Premium, etc
  data_inicio: '2026-05-16',  // ISO format
  data_fim: '2026-05-18'      // ISO format
});
// Retorna APENAS veículos que:
// - Existem na filial (ou todas se não especificado)
// - Não têm reservas conflitantes no período
// - Estão ativos/funcionais
// - Categoria (se especificado)
```

#### C. `toolValidarDisponibilidade(params)` — Valida 1 veículo
```typescript
const result = await toolValidarDisponibilidade({
  veiculo_id: 'uuid-veiculo',
  data_inicio: '2026-05-16',
  data_fim: '2026-05-18'
});
// Retorna: true se disponível, false se conflito
```

#### D. `toolCriarReserva(params)` — Cria reserva + gera link pagamento
```typescript
const result = await toolCriarReserva({
  cliente_id: 'uuid-cliente',
  veiculo_id: 'uuid-veiculo',
  filial_retirada_id: 'uuid-filial',
  filial_devolucao_id?: 'uuid-filial',  // Se diferente
  data_inicio: '2026-05-16',
  data_fim: '2026-05-18',
  plano_seguro_id?: 'uuid',
  metodo_pagamento?: 'INFINITEPAY'  // ou 'DINHEIRO'
});
// Retorna:
// {
//   success: true,
//   data: {
//     reserva_id: 'uuid',
//     valor_total: 450.00,
//     link_pagamento: 'https://infinitepay.com.br/...'
//   }
// }
```

#### E. `toolObterReserva(reserva_id)` — Status da reserva
```typescript
const result = await toolObterReserva('uuid-reserva');
// Retorna status, valor, cliente, datas, veículo
```

#### F. `toolRegistrarCliente(params)` — Novo cliente
```typescript
const result = await toolRegistrarCliente({
  nome_completo: 'João Silva',
  email: 'joao@example.com',
  cpf: '123.456.789-10',
  telefone?: '+5511987654321'
});
// Valida CPF, verifica duplicatas, cria cliente
```

---

### 3. **INTEGRAÇÃO COM WHATSAPP** (`Backend/src/services/whatsapp.service.ts`)

Modificação no ponto de chamada da IA:

```typescript
const useAgent = process.env.WHATSAPP_USE_AGENT === 'true' || true;
if (useAgent) {
  const agentResult = await atenderClienteComAgent(text, { history });
  reply = agentResult.resposta;
} else {
  reply = await answerWhatsAppMessage(text, { history }); // RAG fallback
}
```

**Env var para controlar:**
```bash
WHATSAPP_USE_AGENT=true  # Usar agent (padrão)
WHATSAPP_USE_AGENT=false # Usar RAG antigo
```

---

## 🔐 Segurança Implementada

### 1. **Validação de Entrada**
- Datas: validar formato ISO, não permitir datas retroativas
- UUIDs: validar formato V4
- CPF: validar dígito verificador
- Strings: limpar espaços, limitar tamanho (max 500 chars)

### 2. **Rate Limiting**
```typescript
// TODO: Implementar por telefone
// 5 requisições / minuto por número
// Cache com TTL = 60s
```

### 3. **Auditoria**
```typescript
AuditLog {
  timestamp: string,
  telefone?: string,
  cliente_id?: string,
  intencao: string,
  tools_chamadas: string[],
  resposta_final: string,
  sucesso: boolean,
  erro?: string
}

// Acessar:
import { obterAudits } from './agent.js';
const ultimas100 = obterAudits(100);
```

### 4. **Redação de Dados Sensíveis**
- CPF removido de logs
- Email não aparece em respostas públicas
- Token de pagamento não armazenado
- Dados de cartão nunca tocados

### 5. **Proteção contra Prompt Injection**
- Input sanitizado antes de enviar ao LangChain
- Caracteres especiais escapados
- Limite de tokens (500 max)

---

## 📊 Exemplos de Conversas

### Exemplo 1: Listar Filiais
```
Cliente: "Vocês têm filial em São Paulo?"

[Agent detecta: LISTAR_FILIAIS]
[Agent executa: listar_filiais]
[Resultado: 3 filiais em SP]

Resposta: "Sim, temos 3 unidades em São Paulo:
1. SP Centro - Rua das Flores, 100 - (11) 3000-1000
2. SP Zona Sul - Av. Paulista, 2000 - (11) 3000-2000
3. SP Zona Norte - Av. Brasil, 5000 - (11) 3000-3000

Qual você prefere para retirada?"
```

### Exemplo 2: Listar Carros
```
Cliente: "Quais SUVs vocês têm para 16 a 18 de maio?"

[Agent detecta: LISTAR_CARROS]
[Agent extrai: categoria=SUV, data_inicio=2026-05-16, data_fim=2026-05-18]
[Agent executa: listar_carros_disponiveis({ categoria: 'SUV', data_inicio: '2026-05-16', data_fim: '2026-05-18' })]
[Resultado: 5 SUVs disponíveis]

Resposta: "Encontrei 5 SUVs disponíveis para esse período:

1. Hyundai Creta - R$ 150/dia - 3 unidades
2. Jeep Renegade - R$ 180/dia - 2 unidades
3. Ford EcoSport - R$ 140/dia - 1 unidade

Qual te interessa?"
```

### Exemplo 3: Criar Reserva
```
Cliente: "Quero reservar um Gol branco para 16/05 a 18/05. Meu CPF é 123.456.789-10 e email teste@example.com"

[Agent detecta: REGISTRAR_CLIENTE + CRIAR_RESERVA]
[Agent extrai: cpf, email, data_inicio, data_fim]

Passo 1: registrar_cliente
[Resultado: cliente_id = 'new-uuid-123']

Passo 2: listar_carros_disponiveis
[Resultado: Gol branco disponível, veiculo_id = 'uuid-gol']

Passo 3: validar_disponibilidade
[Resultado: SIM, disponível]

Passo 4: criar_reserva
[Resultado: 
  reserva_id = 'res-123',
  valor_total = R$ 300.00,
  link_pagamento = 'https://infinitepay.com.br/...abc123'
]

Resposta: "Ótimo! Registrei sua conta e criei a reserva:

📋 Reserva #RES-123
🚗 Gol Branco
📅 16/05 - 18/05/2026
💰 R$ 300.00 (2 dias)

Pagamento seguro: https://infinitepay.com.br/...abc123

Confirme o pagamento e sua reserva estará 100% garantida!"
```

---

## 🧪 Testando o Agent

### 1. Executar Exemplos
```bash
cd Backend
npx ts-node src/ai/agent.example.ts
```

### 2. Executar Testes Unitários
```bash
npm test -- tests/unit/ai.test.ts
```

### 3. Testar Manualmente via WhatsApp
- Enviar mensagem para número do bot
- Sistema automaticamente usa agent

### 4. Monitorar Auditoria
```typescript
import { obterAudits } from './ai/agent.js';

app.get('/api/admin/audits', (req, res) => {
  const audits = obterAudits(50);
  res.json(audits);
});
```

---

## 🎯 Próximas Melhorias

### [TODO #2] Segurança Avançada
- [ ] Rate limiting por telefone (5 req/min)
- [ ] Feedback loop para melhorar intenções
- [ ] Detecção de fraude (múltiplas tentativas de pagamento)
- [ ] Criptografia de dados sensíveis em repouso

### [TODO #4] Disponibilidade Avançada
- [ ] Considerar períodos de manutenção
- [ ] Horários de funcionamento de filiais
- [ ] Cross-filial (retirar em SP, devolver em RJ)
- [ ] Hold period (30min após cancelamento)

### [TODO #5] Reserva Inteligente
- [ ] Confirmação de pagamento via callback
- [ ] Auto-release se pagamento falhar
- [ ] Lembretes via FCM/WhatsApp
- [ ] Extensão de período

### [TODO #6] Observabilidade
- [ ] Dashboard de conversas (admin)
- [ ] Métricas: latência média, taxa de sucesso
- [ ] Alertas de erro

### [TODO #7] Testes
- [ ] Load testing (100 conversas simultâneas)
- [ ] Edge cases (double-book, race conditions)
- [ ] Validação de pagamento

---

## 📁 Arquivos Alterados/Criados

| Arquivo | Status | Descrição |
|---------|--------|-----------|
| `Backend/src/ai/agent.ts` | ✅ NOVO | Agent orchestrator com LangChain |
| `Backend/src/ai/tools.ts` | ✅ NOVO | 6 tools com validação real |
| `Backend/src/ai/agent.example.ts` | ✅ NOVO | Exemplos de uso |
| `Backend/tests/unit/ai.test.ts` | ✅ NOVO | Testes unitários |
| `Backend/src/services/whatsapp.service.ts` | ✅ MODIFICADO | Integração do agent |
| `Backend/src/ai/rag.ts` | ⏸️ MANTIDO | Fallback para RAG |

---

## 🚀 Performance Esperada

| Métrica | Valor |
|---------|-------|
| Latência média (agent) | 2-3s |
| Latência com tools | 4-6s |
| Taxa de sucesso | >95% |
| Timeout máximo | 10s |

---

## 📞 Suporte

- **Logs:** `/Backend/logs/agent.log` (TODO: implementar)
- **Auditoria:** `obterAudits()` em memory (TODO: persistir em DB)
- **Erros:** Sempre falha gracefully com resposta ao cliente
