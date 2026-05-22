# Flow de Reserva Melhorado - DriveConnect

## 📋 Sequência de Mensagens

### 1️⃣ Cliente pergunta sobre disponibilidade
**Cliente:** "Qual a disponibilidade de HB20 na unidade FFT para 18 a 20 de maio?"

**Bot:** (Busca no banco) "Na unidade FFT, para as datas de 18 a 20 de maio, encontrei os seguintes veículos disponíveis:
- HB20 AT Hyundai - R$ 150/dia
- Gol Trend - R$ 120/dia
..."

---

### 2️⃣ Cliente seleciona veículo
**Cliente:** "Quero reservar o HB20 AT Hyundai"

**Bot:** Detecta:
- Veículo: HB20 AT Hyundai ✓
- Filial: FFT (do histórico) ✓
- Datas: 18 a 20 de maio (do histórico) ✓
- Dias: 2 dias
- Valor: R$ 300 (2 dias × R$ 150)

**Bot Resposta:**
```
*Confirmação da sua reserva:*
📍 Unidade: FFT
🚗 Veículo: HB20 AT Hyundai
📅 Período: 18/05/2026 até 20/05/2026 (2 dias)
💰 Valor total: R$ 300,00

Responda com *SIM* ou *CONFIRMAR* para prosseguir com o pagamento.
```

---

### 3️⃣ Cliente confirma
**Cliente:** "Confirmar"

**Bot:** Detecta confirmação e gera link de pagamento

**Bot Resposta:**
```
Ótimo! 🎉 Sua reserva foi confirmada!

*Link de pagamento:*
https://driveconnect.com/checkout/RES_1715950800000

Clique no link para finalizar o pagamento. Qualquer dúvida, pode contar comigo!
```

---

## 🔄 Fluxo Técnico

```
Mensagem do Cliente
    ↓
┌─────────────────────────────────────┐
│ atenderClienteComAgent()            │
└─────────────────────────────────────┘
    ↓
    ├─→ [Reserva + Confirmação?]
    │   ├─→ extractReservationDataFromHistory()
    │   │   ├─ Detecta filial (do histórico)
    │   │   ├─ Detecta modelo/veículo
    │   │   ├─ Detecta datas
    │   │   └─ Detecta cliente (CPF, email, phone)
    │   │
    │   ├─→ formatReservationConfirmation()
    │   │   └─ Monta mensagem com todos dados
    │   │
    │   └─→ Retorna: { intencao: AWAITING_CONFIRMATION }
    │
    ├─→ [Confirmação do usuário?]
    │   ├─→ isReservationConfirmation()
    │   │   (busca "sim", "confirmar", "ok", etc)
    │   │
    │   └─→ generatePaymentLink()
    │       └─ Retorna: { paymentLink, intencao: CONFIRMAR_RESERVA }
    │
    └─→ [Fallback - RAG normal]
        └─ Processa como pergunta genérica
```

---

## 📊 Dados Coletados Progressivamente

| Campo | Origem | Quando |
|-------|--------|--------|
| **Filial** | Histórico (ex: "unidade FFT") | Automaticamente do histórico |
| **Veículo** | Mensagem atual (ex: "HB20") | Quando cliente seleciona |
| **Datas** | Histórico (ex: "18 a 20 de maio") | Já fornecido na consulta |
| **Valor** | Calculado (dias × preço/dia) | Na confirmação |
| **Cliente** | Pode ser fornecido na confirmação | Opcional para enviar link |

---

## 🎯 Intenções Detectadas

| Intenção | Quando | Ação |
|----------|--------|------|
| `LISTAR_CARROS` | Cliente pergunta sobre disponibilidade | Busca no BD com filtros |
| `AWAITING_CONFIRMATION` | Cliente seleciona veículo + tem filial/datas | Mostra confirmação |
| `CONFIRMAR_RESERVA` | Cliente responde "sim"/"confirmar" | Gera link pagamento |
| `VER_FOTOS` | Cliente pede fotos | Envia imagens do veículo |
| `LISTAR_FILIAIS` | Cliente pergunta unidades | Lista branches |
| `COTACAO` | Cliente pergunta preço | Informa valores |
| `GENERICO` | Outros casos | RAG normal |

---

## ⚡ Melhorias Implementadas

✅ **Coleta Progressiva**: Dados coletados do histórico (filial) + mensagem atual (veículo)
✅ **Sem Repetição**: Não pede filial se já foi mencionada no histórico
✅ **Confirmação Automática**: Monta mensagem com todos dados antes de confirmar
✅ **Link de Pagamento**: Gerado após confirmação do usuário
✅ **Detecção Robusta**: Reconhece "sim", "confirmar", "ok", "pronto", "blz", etc
✅ **Cálculo Automático**: Calcula valor baseado em dias × preço/dia

---

## 🔗 Integração com Pagamento

Atualmente implementado como placeholder:
```typescript
const paymentLink = `${process.env.APP_URL}/checkout/${reservaId}`;
```

Para integração real, conectar com:
- **Stripe** 
- **MercadoPago**
- **PayPal**
- Sistema próprio

---

## 📝 Exemplos de Uso

### Exemplo 1: Fluxo Rápido (Filial já conhecida)
```
User: "Qual a disponibilidade de HB20 na unidade FFT para 18 a 20 de maio?"
Bot: [lista veículos]

User: "Quero reservar o HB20 AT Hyundai"
Bot: [mostra confirmação com filial do histórico]

User: "Confirmar"
Bot: [envia link de pagamento]
```

### Exemplo 2: Com Devolução Separada
```
User: "Retirada 18 de maio de 2026 e devolução 19 de maio de 2026"
Bot: [extrai ambas as datas corretamente]
```

### Exemplo 3: Diferentes Formas de Confirmação
```
User: "sim"           ✓ Detectado
User: "Confirmar"     ✓ Detectado
User: "Pronto"        ✓ Detectado
User: "OK"            ✓ Detectado
User: "pode ser"      ✓ Detectado
User: "blz"           ✓ Detectado
```

---

## 🐛 Tratamento de Erros

- Se faltar dados (modelo, datas), RAG será acionado para pedir
- Se confirmação falhar, retorna mensagem padrão
- Erros de pagamento não afetam histórico da conversa
- Link gerado mesmo se alguns dados opcionais faltarem

---

## 🔐 Segurança

- CPF/Email/Phone são redacionados no histórico
- Prompt injection é detectado e bloqueado
- Limites de tamanho de entrada (1200 chars)
- Mensagens sensíveis são sanitizadas antes de armazenar
