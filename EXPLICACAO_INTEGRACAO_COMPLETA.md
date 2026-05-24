# 🚀 EXPLICAÇÃO COMPLETA: IA x AGENT x WHATSAPP x PAGAMENTO

## 📋 ÍNDICE

1. [Visão Geral Arquitetura](#visão-geral-arquitetura)
2. [Fluxo Completo Passo a Passo](#fluxo-completo-passo-a-passo)
3. [Componentes Principais](#componentes-principais)
4. [As 6 Tools (Ferramentas da IA)](#as-6-tools-ferramentas-da-ia)
5. [Integração WhatsApp](#integração-whatsapp)
6. [Fluxo de Pagamento](#fluxo-de-pagamento)
7. [Segurança](#segurança)
8. [Exemplos Práticos](#exemplos-práticos)

---

## 🏗️ VISÃO GERAL ARQUITETURA

```
┌──────────────────────────────────────────────────────────────────┐
│                      CLIENTE FINAL                               │
│                   (Usuario no WhatsApp)                           │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ Mensagem de texto
                         │ Ex: "Quero alugar um carro de 16 a 18 de maio"
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│            WHATSAPP CLOUD API (Meta)                             │
│    Recebe a mensagem e encaminha para nosso webhook              │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ POST /whatsapp/webhook
                         │ Verifica assinatura + deduplic.
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│     WHATSAPP.SERVICE.TS (Backend)                                │
│  - Valida mensagem                                               │
│  - Extrai número do cliente                                      │
│  - Busca histórico de conversa anterior                          │
│  - ESCOLHE: Usar AGENT ou RAG (configurable via env var)        │
└────────────────┬──────────────────────────────────────────────────┘
                 │
                 │ processIncomingMessage()
                 │
         ┌───────┴───────┐
         │               │
      AGENT           RAG (fallback)
      (v2.0)           (v1.0 antigo)
         │               │
         │ (padrão)      │ (desativado por default)
         │               │
         ▼               ▼
┌──────────────────┐  ┌──────────────────┐
│   AGENT.TS       │  │   RAG.TS         │
│ (LangChain)      │  │ (Vector Store)   │
│                  │  │                  │
│ 1. Detecta       │  │ Busca docs no    │
│    intenção      │  │ vector DB        │
│                  │  │                  │
│ 2. Extrai        │  │ Gera resposta    │
│    parâmetros    │  │ com contexto     │
│                  │  │                  │
│ 3. Escolhe       │  │ sem actions      │
│    tool(s)       │  │                  │
│                  │  │                  │
│ 4. Executa       │  │ "informativo"    │
│    tool(s)       │  │ apenas           │
│                  │  │                  │
│ 5. Conversa      │  │                  │
│    com IA        │  │                  │
│                  │  │                  │
│ 6. Resposta      │  │                  │
│    acionável     │  │                  │
└────────┬─────────┘  └──────────────────┘
         │
         │ Toma decisões com base em tools
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│     DATABASE (PostgreSQL)                                         │
│  - Filiais      (unidades)                                       │
│  - Veículos     (carros)                                         │
│  - Reservas     (agendamentos)                                   │
│  - Clientes     (usuários)                                       │
│  - Modelos      (categorias de carro)                            │
│  - Preços       (diárias e seguros)                              │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ Query em tempo real
                         │ (dados atualizados)
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│     TOOLS.TS (6 Ferramentas executáveis)                         │
│  1. toolListarFiliais()          → Busca unidades                │
│  2. toolListarCarrosDisponiveis() → Filtra por data/local        │
│  3. toolValidarDisponibilidade() → Valida 1 carro               │
│  4. toolCriarReserva()           → Cria reserva + link pag.      │
│  5. toolObterReserva()           → Status da reserva             │
│  6. toolRegistrarCliente()       → Novo cliente                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ Executa ações reais no BD
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│     RESPOSTA PROCESSADA                                          │
│  "Encontrei 3 carros disponíveis em SP:                         │
│   1. Honda Civic - R$ 150/dia                                    │
│   2. Toyota Corolla - R$ 160/dia                                 │
│   3. Hyundai HB20 - R$ 120/dia                                   │
│                                                                   │
│   Qual você prefere? Responda com o número."                    │
│                                                                   │
│   [Link de pagamento será gerado após escolha]                  │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ sendMessage(to, text)
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│            WHATSAPP CLOUD API (Meta)                             │
│    Envia mensagem de volta para o cliente                        │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│                      CLIENTE FINAL                               │
│              (Recebe resposta no WhatsApp)                        │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🔄 FLUXO COMPLETO PASSO A PASSO

### Exemplo Real: Cliente quer alugar um carro

```
PASSO 1: Cliente envia mensagem
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Cliente: "Oi, quero alugar um carro em São Paulo de 16 a 18 de maio"

PASSO 2: WhatsApp Service recebe webhook
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ POST /whatsapp/webhook recebe a mensagem
✓ Verifica assinatura (segurança)
✓ Deduplicação (evita processar mensagem 2x)
✓ Busca número do cliente: +5511987654321
✓ Busca histórico de conversa anterior (context)
✓ Cria/atualiza conversa na DB

PASSO 3: Agent processando (AGENT.TS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1] DETECÇÃO DE INTENÇÃO
   - Input: "quero alugar um carro em sp de 16 a 18 de maio"
   - Análise: contém "alugar" + datas + local
   - Resultado: INTENÇÃO = "CRIAR_RESERVA"

[2] EXTRAÇÃO DE PARÂMETROS
   - Data início: "16/05/2026" → "2026-05-16"
   - Data fim: "18/05/2026" → "2026-05-18"
   - Local: "São Paulo" → [busca filiais em SP no BD]
   - Outros: categoria não mencionada (vai pedir depois)

[3] ESCOLHE TOOL(S) A EXECUTAR
   - Objetivo: cliente quer alugar
   - Falta: sabe datas/local, mas não sabe quais carros tem
   - Actions:
     a) toolListarFiliais() → para confirmar local
     b) toolListarCarrosDisponiveis() → para mostrar opções

[4] EXECUTA AS TOOLS
   
   📍 Tool A: toolListarFiliais()
   ─────────────────────────────
   SELECT * FROM filial WHERE cidade = 'São Paulo' AND ativo = TRUE
   
   Resultado:
   {
     id: "uuid-sp-centro",
     nome: "SP Centro",
     cidade: "São Paulo",
     uf: "SP",
     endereco: "Av. Paulista, 1000",
     ativo: true
   }

   📍 Tool B: toolListarCarrosDisponiveis()
   ─────────────────────────────────────────
   Params: {
     filial_id: "uuid-sp-centro",
     data_inicio: "2026-05-16",
     data_fim: "2026-05-18"
   }
   
   Query complexa:
   SELECT v.id, v.placa, m.modelo, m.marca, m.categoria, 
          t.preco_diaria, v.status
   FROM veiculo v
   JOIN modelo m ON v.modelo_id = m.id
   JOIN tabela_preco t ON m.id = t.modelo_id
   WHERE v.filial_id = $filial_id
     AND v.status = 'DISPONIVEL'
     AND v.deletado_em IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM reserva r
       WHERE r.veiculo_id = v.id
         AND r.status IN ('PENDENTE_PAGAMENTO', 'RESERVADA', 'ATIVA')
         AND r.data_inicio < '2026-05-18'
         AND r.data_fim > '2026-05-16'
     )
   ORDER BY m.categoria, t.preco_diaria
   
   Resultado: [
     {
       id: "uuid-honda",
       placa: "ABC-1234",
       modelo: "Civic",
       marca: "Honda",
       categoria: "Sedan",
       preco_diaria: 150.00,
       status: "DISPONIVEL"
     },
     {
       id: "uuid-corolla",
       placa: "XYZ-5678",
       modelo: "Corolla",
       marca: "Toyota",
       categoria: "Sedan",
       preco_diaria: 160.00,
       status: "DISPONIVEL"
     },
     {
       id: "uuid-hb20",
       placa: "DEF-9012",
       modelo: "HB20",
       marca: "Hyundai",
       categoria: "Econômico",
       preco_diaria: 120.00,
       status: "DISPONIVEL"
     }
   ]

[5] IA CONVERSA COM O CLIENTE
   - Processa resultado das tools
   - Gera resposta conversacional
   - Formato: WhatsApp (curto, direto, sem markdown)
   - Exemplo:
     
     "Ótimo! Encontrei 3 carros disponíveis em São Paulo para 16 a 18 de maio:
     
     1️⃣ Honda Civic - Sedan - R$ 150/dia
     2️⃣ Toyota Corolla - Sedan - R$ 160/dia  
     3️⃣ Hyundai HB20 - Econômico - R$ 120/dia
     
     Qual você prefere? Me responde só com o número! 😊"

PASSO 4: Envia resposta via WhatsApp
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
sendMessage(to, text)
   ↓
Faz POST na WhatsApp Cloud API
   ↓
Meta encaminha para o cliente

PASSO 5: Cliente responde
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Cliente: "1"
   ↓
Voltar ao PASSO 2 (webhook novo)
   ↓
Agent detecta: "CRIAR_RESERVA" (cliente escolheu carro 1)
   ↓
Agent executa: toolCriarReserva({
   cliente_id: "uuid-cliente",
   veiculo_id: "uuid-honda",
   filial_retirada_id: "uuid-sp-centro",
   data_inicio: "2026-05-16",
   data_fim: "2026-05-18"
})

PASSO 6: Tool cria a reserva
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Operações no BD:
1. Calcula valor total: 2 dias × R$ 150/dia = R$ 300
2. Adiciona seguro básico (se houver): +R$ 50
3. Cria registro em `reserva` table:
   {
     id: "uuid-reserva-123",
     cliente_id: "uuid-cliente",
     veiculo_id: "uuid-honda",
     status: "PENDENTE_PAGAMENTO",
     data_inicio: "2026-05-16",
     data_fim: "2026-05-18",
     valor_total: 350.00,
     metodo_pagamento: "INFINITEPAY"
   }
4. Gera link de pagamento via InfinitePay API
5. Retorna:
   {
     reserva_id: "uuid-reserva-123",
     link_pagamento: "https://infinitepay.com.br/checkout/xyz123",
     valor_total: 350.00,
     mensagem: "Reserva criada com sucesso!"
   }

PASSO 7: Resposta da IA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"Perfeito! Reservei seu Honda Civic de 16 a 18 de maio em São Paulo.

Resumo:
📅 Datas: 16-18 de maio (2 dias)
🚗 Veículo: Honda Civic (Placa ABC-1234)
💰 Valor: R$ 350 (aluguel + seguro)
📍 Retirada: SP Centro - Av. Paulista, 1000

Clique aqui para confirmar pagamento:
👉 https://infinitepay.com.br/checkout/xyz123

Após pagamento, sua reserva é confirmada e você recebe comprovante!"

PASSO 8: Cliente clica no link
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Vai para checkout da InfinitePay
Preenche dados de cartão
Confirma pagamento

PASSO 9: Webhook de pagamento (PAYMENT.ROUTES.TS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
InfinitePay → POST /pagamento/webhook
{
  order_nsu: "uuid-reserva-123",
  transaction_nsu: "trans-12345",
  status: "APPROVED"
}
   ↓
Backend confirma reserva:
  UPDATE reserva SET status = 'RESERVADA' WHERE id = 'uuid-reserva-123'
   ↓
Notifica cliente via WhatsApp:
  "✅ Seu pagamento foi confirmado! Reserva agora é válida.
   
   Seu comprovante foi enviado por email.
   Recado: compareça 30 min antes da retirada."

✅ FLUXO COMPLETO FINALIZADO!
```

---

## 🎯 COMPONENTES PRINCIPAIS

### 1. **AGENT.TS** - O "Cérebro" Inteligente

**O que faz:**
- Entende a intenção do cliente (detecta o que ele quer fazer)
- Extrai informações estruturadas da mensagem
- Escolhe qual(is) tool(s) usar
- Executa as tools
- Conversa de forma natural

**Intenções Detectadas:**

| Intenção | Exemplo | Actions |
|----------|---------|---------|
| **LISTAR_FILIAIS** | "Vocês têm filial em SP?" | Busca filiais no BD |
| **LISTAR_CARROS** | "Que carros vocês têm?" | Lista frota disponível |
| **COTACAO** | "Quanto custa alugar um Civic?" | Calcula preço |
| **CRIAR_RESERVA** | "Quero alugar um carro" | Fluxo completo reserva |
| **RASTREAR_RESERVA** | "Qual é o status?" | Busca código reserva |
| **REGISTRAR_CLIENTE** | "Como me registro?" | Cadastra novo cliente |
| **GENERICO** | "Como é política de cancelamento?" | Busca no vector store |

**Como funciona:**

```typescript
// Entrada
const entrada = "Quero alugar um carro de 16 a 18 de maio em SP";

// Processamento no Agent
1. Sanitiza input (remove caracteres perigosos, limita tamanho)
2. Detecta intenção: "CRIAR_RESERVA"
3. Extrai parâmetros:
   - data_inicio: "2026-05-16"
   - data_fim: "2026-05-18"
   - local: "São Paulo"
4. Escolhe tools: [toolListarFiliais, toolListarCarrosDisponiveis]
5. Executa tools
6. Processa resultado
7. Gera resposta conversacional

// Saída
{
  resposta: "Encontrei 3 carros...",
  intencao: "CRIAR_RESERVA",
  tools_usadas: ["toolListarFiliais", "toolListarCarrosDisponiveis"],
  parametros_extraidos: {
    data_inicio: "2026-05-16",
    data_fim: "2026-05-18",
    local: "São Paulo"
  }
}
```

**Localização:** [Backend/src/ai/agent.ts](Backend/src/ai/agent.ts)

---

### 2. **TOOLS.TS** - As Ferramentas Executáveis

São como funções que a IA pode chamar para fazer coisas reais no banco de dados.

Cada tool:
- ✅ Valida inputs
- ✅ Consulta BD
- ✅ Retorna estrutura padronizada
- ✅ Trata erros gracefully

**Localização:** [Backend/src/ai/tools.ts](Backend/src/ai/tools.ts)

---

### 3. **RAG.TS** - O "Fallback" (Versão Antiga)

Se a IA Agent não conseguir resolver (ex: pergunta muito genérica), volta para o sistema RAG antigo:

**RAG = Retrieval Augmented Generation**

- Busca documentos relevantes no vector store (base de conhecimento)
- Gera resposta informativa
- NÃO executa ações no BD (apenas informativo)

**Quando usa:**
```typescript
// Em whatsapp.service.ts
const useAgent = process.env.WHATSAPP_USE_AGENT === 'true' || true;
if (useAgent) {
  // Usa AGENT (padrão)
} else {
  // Usa RAG antigo (fallback)
}
```

---

## 🔧 AS 6 TOOLS (FERRAMENTAS DA IA)

### Tool 1: `toolListarFiliais()`

**O que faz:** Busca todas as filiais ativas.

**Entrada:** Nenhuma

**Saída:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-1",
      "nome": "SP Centro",
      "cidade": "São Paulo",
      "uf": "SP",
      "endereco": "Av. Paulista, 1000",
      "ativo": true
    },
    {
      "id": "uuid-2",
      "nome": "SP Zona Sul",
      "cidade": "São Paulo",
      "uf": "SP",
      "endereco": "Av. Brasil, 5000",
      "ativo": true
    }
  ],
  "metadata": {
    "total": 2
  }
}
```

**Query SQL:**
```sql
SELECT id, nome, cidade, uf, endereco, ativo
FROM filial
WHERE deletado_em IS NULL AND ativo = TRUE
ORDER BY cidade, nome
```

---

### Tool 2: `toolListarCarrosDisponiveis(params)`

**O que faz:** Busca carros disponíveis num período específico, numa filial específica.

**Entrada:**
```typescript
{
  filial_id?: "uuid-filial",      // Opcional
  categoria?: "SUV",               // Opcional: Econômico, SUV, Sedan, Premium
  data_inicio: "2026-05-16",       // Obrigatório (ISO format)
  data_fim: "2026-05-18"           // Obrigatório (ISO format)
}
```

**Validações:**
- ✅ Datas em formato ISO válido
- ✅ Data fim > data início
- ✅ Diferença máxima: 30 dias
- ✅ Não permitir datas retroativas

**Saída:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-veiculo",
      "placa": "ABC-1234",
      "modelo": "Civic",
      "marca": "Honda",
      "categoria": "Sedan",
      "ano": 2024,
      "cor": "Prata",
      "filial_id": "uuid-filial",
      "filial_nome": "SP Centro",
      "preco_diaria": 150.00,
      "status": "DISPONIVEL",
      "imagem_url": "https://..."
    }
  ],
  "metadata": {
    "total": 3,
    "filtro_filial": "uuid-filial",
    "filtro_categoria": null,
    "filtro_datas": ["2026-05-16", "2026-05-18"]
  }
}
```

**Query SQL (complexa):**
```sql
SELECT v.id, v.placa, m.modelo, m.marca, m.categoria, v.ano, v.cor,
       v.filial_id, f.nome as filial_nome, t.preco_diaria, v.status
FROM veiculo v
JOIN modelo m ON v.modelo_id = m.id
JOIN filial f ON v.filial_id = f.id
LEFT JOIN tabela_preco t ON m.id = t.modelo_id AND f.id = t.filial_id
WHERE v.filial_id = $1
  AND v.status = 'DISPONIVEL'
  AND v.deletado_em IS NULL
  -- ⚠️ CHAVE: Garante que não há reservas conflitantes
  AND NOT EXISTS (
    SELECT 1 FROM reserva r
    WHERE r.veiculo_id = v.id
      AND r.status IN ('PENDENTE_PAGAMENTO', 'RESERVADA', 'ATIVA')
      AND r.data_inicio < $3         -- data_fim de entrada
      AND r.data_fim > $2            -- data_inicio de entrada
      AND r.deletado_em IS NULL
  )
ORDER BY m.categoria, t.preco_diaria ASC
```

**Exemplos de uso:**
```typescript
// Busca todos os carros de SP Centro de 16-18 de maio
toolListarCarrosDisponiveis({
  filial_id: "uuid-sp-centro",
  data_inicio: "2026-05-16",
  data_fim: "2026-05-18"
})

// Busca apenas SUVs disponíveis
toolListarCarrosDisponiveis({
  categoria: "SUV",
  data_inicio: "2026-05-16",
  data_fim: "2026-05-18"
})

// Busca em qualquer filial
toolListarCarrosDisponiveis({
  data_inicio: "2026-05-16",
  data_fim: "2026-05-18"
})
```

---

### Tool 3: `toolValidarDisponibilidade(params)`

**O que faz:** Valida se um carro específico está disponível.

**Entrada:**
```typescript
{
  veiculo_id: "uuid-veiculo",
  data_inicio: "2026-05-16",
  data_fim: "2026-05-18"
}
```

**Saída:**
```json
{
  "success": true,
  "data": {
    "disponivel": true,
    "motivo": null,
    "veiculo": {
      "id": "uuid-veiculo",
      "placa": "ABC-1234",
      "modelo": "Honda Civic"
    }
  }
}
```

**Ou se não estiver disponível:**
```json
{
  "success": true,
  "data": {
    "disponivel": false,
    "motivo": "Veículo já possui reserva no período",
    "veiculo": {
      "id": "uuid-veiculo",
      "placa": "ABC-1234",
      "modelo": "Honda Civic"
    }
  }
}
```

**Validações:**
1. Valida datas (ISO format, data fim > data início)
2. Verifica se veículo existe
3. Verifica status do veículo (deve ser DISPONIVEL)
4. Verifica conflitos de reserva

---

### Tool 4: `toolCriarReserva(params)` ⭐ A MAIS IMPORTANTE

**O que faz:** Cria uma reserva completa, calcula valor total e gera link de pagamento.

**Entrada:**
```typescript
{
  cliente_id: "uuid-cliente",
  veiculo_id: "uuid-veiculo",
  filial_retirada_id: "uuid-filial-1",
  filial_devolucao_id?: "uuid-filial-2",  // Se diferente (optional)
  data_inicio: "2026-05-16",
  data_fim: "2026-05-18",
  plano_seguro_id?: "uuid-seguro",        // Se custom
  metodo_pagamento?: "INFINITEPAY"        // ou "DINHEIRO"
}
```

**Operações:**
1. ✅ Valida cliente (existe no BD)
2. ✅ Valida veículo (existe no BD)
3. ✅ Valida filiais (existem no BD)
4. ✅ Valida datas (formato, range)
5. ✅ Calcula valor da diária
6. ✅ Busca seguro (ou usa padrão)
7. ✅ Calcula valor total
8. ✅ Cria registro de reserva com status `PENDENTE_PAGAMENTO`
9. ✅ Gera link de pagamento via InfinitePay API
10. ✅ Retorna dados da reserva

**Saída:**
```json
{
  "success": true,
  "data": {
    "reserva_id": "uuid-reserva-123",
    "link_pagamento": "https://infinitepay.com.br/checkout/abc123xyz",
    "valor_total": 350.00,
    "status": "PENDENTE_PAGAMENTO",
    "mensagem": "Reserva criada com sucesso!"
  }
}
```

**Exemplo:**
```typescript
const resultado = await toolCriarReserva({
  cliente_id: "uuid-cliente-456",
  veiculo_id: "uuid-honda-civic",
  filial_retirada_id: "uuid-sp-centro",
  data_inicio: "2026-05-16",
  data_fim: "2026-05-18",
  metodo_pagamento: "INFINITEPAY"
});

console.log(resultado.data.link_pagamento);
// https://infinitepay.com.br/checkout/abc123xyz
```

---

### Tool 5: `toolObterReserva(reserva_id)`

**O que faz:** Busca status completo de uma reserva.

**Entrada:**
```typescript
"uuid-reserva-123"
```

**Saída:**
```json
{
  "success": true,
  "data": {
    "id": "uuid-reserva-123",
    "cliente_nome": "João Silva",
    "veiculo_modelo": "Honda Civic",
    "veiculo_placa": "ABC-1234",
    "status": "RESERVADA",
    "data_inicio": "2026-05-16",
    "data_fim": "2026-05-18",
    "filial_retirada": "SP Centro",
    "filial_devolucao": "SP Centro",
    "valor_aluguel": 300.00,
    "valor_seguro": 50.00,
    "valor_total": 350.00,
    "metodo_pagamento": "INFINITEPAY",
    "status_pagamento": "CONFIRMADO",
    "data_pagamento": "2026-05-15T14:30:00Z"
  }
}
```

**Possíveis status:**
- `PENDENTE_PAGAMENTO` - Aguardando cliente pagar
- `RESERVADA` - Pagamento confirmado
- `ATIVA` - Cliente pegou o carro
- `CONCLUIDA` - Carro foi devolvido
- `CANCELADA` - Cliente cancelou

---

### Tool 6: `toolRegistrarCliente(params)`

**O que faz:** Registra um novo cliente no sistema.

**Entrada:**
```typescript
{
  nome_completo: "João Silva",
  email: "joao@example.com",
  cpf: "123.456.789-10",
  telefone?: "+5511987654321"  // Optional
}
```

**Validações:**
- ✅ CPF válido (verifica dígito verificador)
- ✅ Email válido (formato)
- ✅ Telefone válido (10-13 dígitos)
- ✅ Verifica duplicatas (CPF ou email já existe?)
- ✅ Sanitiza inputs

**Saída:**
```json
{
  "success": true,
  "data": {
    "cliente_id": "uuid-cliente-novo",
    "nome_completo": "João Silva",
    "email": "joao@example.com",
    "cpf": "***.***.***-10",
    "telefone": "+5511987654321",
    "data_registro": "2026-05-24T10:00:00Z",
    "mensagem": "Novo cliente registrado com sucesso!"
  }
}
```

**Se falhar (CPF duplicado):**
```json
{
  "success": false,
  "error": "CPF já registrado no sistema"
}
```

---

## 💬 INTEGRAÇÃO WHATSAPP

### Fluxo de Webhook

```
Cliente envia msg no WhatsApp
        ↓
Meta (WhatsApp Cloud API)
        ↓
POST /whatsapp/webhook
(nosso backend recebe)
        ↓
Arquivo: Backend/src/routes/whatsapp.routes.ts
Função: router.post('/webhook', handleWebhook)
        ↓
1. Valida assinatura (segurança)
2. Deduplicação (evita processar 2x)
3. Extrai número do cliente
4. Busca histórico de conversa
5. Encaminha para processIncomingMessage()
        ↓
Backend/src/services/whatsapp.service.ts
processIncomingMessage(telefone, mensagem, histórico)
        ↓
❓ ESCOLHE:
   - Usar AGENT (recomendado) → agent.ts
   - Usar RAG (fallback) → rag.ts
   (controlado por env var: WHATSAPP_USE_AGENT)
        ↓
Gera resposta
        ↓
sendMessage(telefone, resposta)
        ↓
Faz POST na WhatsApp Cloud API
        ↓
Meta encaminha para cliente
        ↓
Cliente recebe no WhatsApp
```

### Configuração de Ambiente

```bash
# ============== WHATSAPP ==============

# Token de segurança (verifica requests legítimas)
WHATSAPP_VERIFY_TOKEN=seu_token_aqui

# Credenciais da Meta
WHATSAPP_ACCESS_TOKEN=EAAi8...seu_access_token
WHATSAPP_PHONE_NUMBER_ID=1234567890
WHATSAPP_GRAPH_API_VERSION=v19.0

# App Secret (verifica assinatura do webhook)
WHATSAPP_APP_SECRET=seu_app_secret

# Rate limiting
WHATSAPP_RATE_LIMIT_WINDOW_MS=60000    # Janela: 60 seg
WHATSAPP_RATE_LIMIT_MAX=120            # Max 120 req/min

# IA (AGENT vs RAG)
WHATSAPP_USE_AGENT=true                # true = Agent, false = RAG

# Deduplicação (evita processar msg 2x)
WHATSAPP_DEDUPE_TTL_MS=600000          # 10 minutos

# Timeout
WHATSAPP_TIMEOUT_MS=10000              # 10 segundos
```

### Exemplo de Webhook Recebido

```json
{
  "entry": [
    {
      "changes": [
        {
          "value": {
            "messages": [
              {
                "from": "5511987654321",
                "id": "wamid.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijkl",
                "timestamp": "1621884262",
                "type": "text",
                "text": {
                  "body": "Oi, quero alugar um carro de 16 a 18 de maio"
                }
              }
            ],
            "statuses": []
          }
        }
      ]
    }
  ]
}
```

---

## 💳 FLUXO DE PAGAMENTO

### Integração com InfinitePay

```
Agent executa toolCriarReserva()
        ↓
Cria registro de reserva (status: PENDENTE_PAGAMENTO)
        ↓
Chama InfinitePay API para gerar link
        ↓
Retorna link de pagamento
        ↓
IA responde com link para cliente
        ↓
Cliente clica no link
        ↓
Abre checkout da InfinitePay
        ↓
Cliente preenche dados do cartão
        ↓
InfinitePay processa pagamento
        ↓
Se aprovado → InfinitePay faz callback
        ↓
POST /pagamento/webhook
        ↓
Backend confirma pagamento
        ↓
UPDATE reserva SET status = 'RESERVADA'
        ↓
Notifica cliente via WhatsApp
        ↓
✅ Fluxo finalizado
```

### Arquivo de Rotas: payment.routes.ts

**Endpoint 1: POST /pagamento/iniciar**
- Inicia o fluxo de pagamento
- Cria reserva pendente
- Retorna link de checkout

**Endpoint 2: POST /pagamento/webhook**
- Recebe callback do InfinitePay
- Confirma pagamento
- Notifica cliente

**Endpoint 3: GET /pagamento/status/:reservaId**
- Fallback de polling
- Cliente pode consultar status

---

## 🔐 SEGURANÇA

### 1. Validação de Entrada

```typescript
// ✅ Sanitização de CPF
cpf = "123.456.789-10"
// Verifica dígito verificador
// Retorna erro se inválido

// ✅ Validação de Datas
data = "2026-05-16"
// Verifica formato ISO
// Não permite datas retroativas
// Máximo 30 dias de diferença

// ✅ Validação de UUIDs
uuid = "550e8400-e29b-41d4-a716-446655440000"
// Verifica se é valid V4 UUID

// ✅ Limite de caracteres
text.length <= 1200  // Max 1200 chars
```

### 2. Rate Limiting

```typescript
// 5 requisições por minuto por número de telefone
// Cache com TTL = 60 segundos
// Se exceder → retorna 429 (Too Many Requests)

const RATE_LIMIT = 5;
const TIME_WINDOW = 60000; // 1 min

// Mantém Map de requisições por telefone
const requestMap = new Map<string, number[]>();

if (requestMap.has(telefone)) {
  const timestamps = requestMap.get(telefone) || [];
  // Remove timestamps antigos (fora da janela)
  const recentRequests = timestamps.filter(
    t => Date.now() - t < TIME_WINDOW
  );
  if (recentRequests.length >= RATE_LIMIT) {
    throw new Error('Rate limit exceeded');
  }
}
```

### 3. Detecção de Prompt Injection

```typescript
// Detecta padrões maliciosos
function isPromptInjectionAttempt(text: string): boolean {
  const patterns = [
    /ignore.*instruction/i,
    /forgot.*prompt/i,
    /execute.*command/i,
    /override/i,
    /escape|jailbreak/i
  ];
  
  return patterns.some(p => p.test(text));
}

// Se detectado → recusa e retoma atendimento
if (isPromptInjectionAttempt(mensagem)) {
  return "Desculpe, não entendi. Como posso ajudar com sua locação? 🚗";
}
```

### 4. Redação de Dados Sensíveis (PII)

```typescript
// Antes de logar ou exibir
function redactSensitive(text: string): string {
  text = text.replace(/\d{3}\.\d{3}\.\d{3}-\d{2}/g, '[REDACTED_CPF]');
  text = text.replace(/\+?\d{10,13}/g, '[REDACTED_PHONE]');
  text = text.replace(/[^@]+@[^@]+\.[^@]+/g, '[REDACTED_EMAIL]');
  return text;
}

// LOG: "Cliente [REDACTED_PHONE] enviou: Oi..."
// LOG: "CPF: [REDACTED_CPF]"
```

### 5. Assinatura de Webhook

```typescript
// Meta assina todos os webhooks
// Verificamos a assinatura para garantir que é mesmo da Meta

function verifySignature(req, secret) {
  const signature = req.headers['x-hub-signature-256'];
  const body = req.body;
  
  const hash = crypto
    .createHmac('sha256', secret)
    .update(body)
    .digest('hex');
  
  const expected = `sha256=${hash}`;
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}
```

---

## 📚 EXEMPLOS PRÁTICOS

### Exemplo 1: Cliente quer listar filiais

```
👤 Cliente: "Vocês têm filial em Brasília?"

🤖 Agent:
   1. Detecta: INTENÇÃO = "LISTAR_FILIAIS"
   2. Executa: toolListarFiliais()
   3. Resultado: [SP Centro, SP Sul, RJ Centro, Brasília]
   4. Filtra: Apenas "Brasília"
   5. Formata resposta

📱 Resposta WhatsApp:
"Sim! Temos filial em Brasília:

📍 Brasília Centro
   Endereço: SCS Bloco B, Edifício Principal, 400
   Telefone: (61) 3000-4000
   Horário: Seg-Dom 08:00-18:00

Quer fazer uma reserva? 😊"
```

---

### Exemplo 2: Cliente quer saber preços

```
👤 Cliente: "Quanto custa alugar um Civic de 16 a 18 de maio?"

🤖 Agent:
   1. Detecta: INTENÇÃO = "COTACAO"
   2. Extrai:
      - Modelo: Civic
      - Data início: 2026-05-16
      - Data fim: 2026-05-18
   3. Executa: toolListarCarrosDisponiveis({
      categoria: "Sedan" (por que Civic é sedan),
      data_inicio: "2026-05-16",
      data_fim: "2026-05-18"
   })
   4. Filtra Civics
   5. Calcula valor total

📱 Resposta WhatsApp:
"Encontrei Honda Civic disponível! 🚗

📅 Período: 16-18 de maio (2 dias)
💰 Diária: R$ 150/dia
📊 Total aluguel: R$ 300
🛡️ Seguro: R$ 50 (opcional)
💵 Total: R$ 350

Quer fazer a reserva? Me passa a filial de retirada! 😊"
```

---

### Exemplo 3: Cliente quer rastrear reserva

```
👤 Cliente: "Qual é o status da minha reserva UUID-123?"

🤖 Agent:
   1. Detecta: INTENÇÃO = "RASTREAR_RESERVA"
   2. Extrai: reserva_id = "UUID-123"
   3. Executa: toolObterReserva("UUID-123")
   4. Retorna: {
      status: "ATIVA",
      veiculo: "Honda Civic - ABC-1234",
      retirada: "16/05/2026 10:00",
      devolução: "18/05/2026 10:00",
      filial: "SP Centro"
   }

📱 Resposta WhatsApp:
"✅ Sua reserva está ATIVA!

🚗 Honda Civic (Placa ABC-1234)
📅 Retirada: 16/05/2026 - 10:00
🔄 Devolução: 18/05/2026 - 10:00
📍 Filial: SP Centro

⚠️ Recado: compareça 30 min antes!

Precisa de algo mais? 😊"
```

---

### Exemplo 4: Cliente se registra

```
👤 Cliente: "Como eu me registro para alugar?"

🤖 Agent:
   1. Detecta: INTENÇÃO = "REGISTRAR_CLIENTE"
   2. Pergunta (em conversas subsequentes):
      - Nome completo?
      - Email?
      - CPF?

👤 Cliente (próximas mensagens):
      "João Silva"
      "joao@email.com"
      "123.456.789-10"

🤖 Agent:
   1. Coleta tudo
   2. Executa: toolRegistrarCliente({
      nome_completo: "João Silva",
      email: "joao@email.com",
      cpf: "123.456.789-10"
   })
   3. Valida CPF
   4. Verifica duplicatas
   5. Cria cliente no BD

📱 Resposta WhatsApp:
"🎉 Bem-vindo, João!

Seu cadastro foi criado com sucesso!

Agora você pode:
✓ Alugar carros
✓ Ver suas reservas
✓ Rastrear status

Qual carro você gostaria de alugar? 🚗"
```

---

## 🔍 RESUMO VISUAL

```
┌─────────────────────────────────────────────────────┐
│         ARQUITETURA EM CAMADAS                      │
└─────────────────────────────────────────────────────┘

┌─ LAYER 1: CLIENT ─────────────────────────────────┐
│ WhatsApp (cliente envia mensagem)                  │
└───────────────────────────────────────────────────┘
                    ↓
┌─ LAYER 2: WEBHOOK ────────────────────────────────┐
│ whatsapp.routes.ts                                 │
│ - Valida assinatura (segurança)                   │
│ - Deduplicação                                     │
│ - Routing para processamento                       │
└───────────────────────────────────────────────────┘
                    ↓
┌─ LAYER 3: PROCESSAMENTO ──────────────────────────┐
│ whatsapp.service.ts                                │
│ - processIncomingMessage()                         │
│ - Escolhe: AGENT ou RAG                            │
│ - Mantém histórico de conversa                     │
└───────────────────────────────────────────────────┘
                    ↓
┌─ LAYER 4: IA (ESCOLHA DUPLA) ─────────────────────┐
│                                                     │
│ ┌─ AGENT.TS ────────────────────┐                 │
│ │ (padrão, recomendado)         │                 │
│ │ - Detecta intenção            │                 │
│ │ - Extrai parâmetros           │                 │
│ │ - Escolhe + executa tools     │                 │
│ │ - Conversa inteligente        │                 │
│ └─────────────────────────────────┘                │
│                                                     │
│        ⬇️ (ou fallback para)                       │
│                                                     │
│ ┌─ RAG.TS ──────────────────────┐                 │
│ │ (antigo, informativo)         │                 │
│ │ - Busca em vector store       │                 │
│ │ - Sem execução de ações       │                 │
│ └────────────────────────────────┘                 │
└───────────────────────────────────────────────────┘
                    ↓
┌─ LAYER 5: TOOLS ──────────────────────────────────┐
│ tools.ts (6 ferramentas executáveis)               │
│ 1. toolListarFiliais()                             │
│ 2. toolListarCarrosDisponiveis()                   │
│ 3. toolValidarDisponibilidade()                    │
│ 4. toolCriarReserva()                              │
│ 5. toolObterReserva()                              │
│ 6. toolRegistrarCliente()                          │
└───────────────────────────────────────────────────┘
                    ↓
┌─ LAYER 6: DATABASE ───────────────────────────────┐
│ PostgreSQL                                         │
│ - filial (unidades)                                │
│ - veiculo (carros)                                 │
│ - reserva (agendamentos)                           │
│ - cliente (usuários)                               │
│ - modelo (categorias)                              │
│ - tabela_preco (preços)                            │
└───────────────────────────────────────────────────┘
                    ↓
┌─ LAYER 7: RESPOSTA ───────────────────────────────┐
│ sendMessage(telefone, resposta)                    │
│ → WhatsApp Cloud API (Meta)                        │
│ → Envia para cliente no WhatsApp                   │
└───────────────────────────────────────────────────┘
```

---

## ✅ CHECKLIST DE ENTENDIMENTO

Depois de ler esse documento, você deve entender:

- ✅ Como a IA Agent funciona (detecta intenção, extrai parâmetros, executa tools)
- ✅ As 6 tools disponíveis e o que cada uma faz
- ✅ Diferença entre AGENT e RAG
- ✅ Como o WhatsApp se integra
- ✅ Fluxo completo de uma reserva (da mensagem até pagamento)
- ✅ Medidas de segurança implementadas
- ✅ Como configurar via env vars
- ✅ Exemplos práticos de conversas

---

## 🚀 PRÓXIMAS MELHORIAS

1. **Rate Limiting avançado** - Por IP + telefone + ação
2. **Machine Learning** - Aprender padrões de clientes
3. **Multi-idioma** - Suporte a outros idiomas
4. **Notificações automáticas** - Lembrete 24h antes da retirada
5. **Integração com CRM** - Histórico completo do cliente
6. **Analytics** - Dashboard de uso e métricas

---

**Última atualização:** 24/05/2026  
**Versão:** 2.0  
**Status:** ✅ Produção
