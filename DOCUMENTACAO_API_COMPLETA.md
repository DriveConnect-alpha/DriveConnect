# 📡 DOCUMENTAÇÃO COMPLETA DA API DRIVECONNECT

## 📋 ÍNDICE

1. [Informações Gerais](#informações-gerais)
2. [Autenticação](#autenticação)
3. [Endpoints por Módulo](#endpoints-por-módulo)
   - [Autenticação & Usuários](#autenticação--usuários)
   - [Filiais](#filiais)
   - [Veículos](#veículos)
   - [Modelos](#modelos)
   - [Reservas](#reservas)
   - [Pagamento](#pagamento)
   - [WhatsApp](#whatsapp)
   - [Notificações](#notificações)
   - [Relatórios](#relatórios)
4. [Códigos de Status HTTP](#códigos-de-status-http)
5. [Tratamento de Erros](#tratamento-de-erros)
6. [Rate Limiting](#rate-limiting)
7. [Exemplos de Requisição](#exemplos-de-requisição)

---

## 📌 INFORMAÇÕES GERAIS

**Base URL:** `https://api.driveconnect.com.br`  
**Versão:** 2.0  
**Autenticação:** JWT (Bearer Token)  
**Content-Type:** `application/json` (exceto uploads)  
**Timeout:** 10 segundos

### Tipos de Usuários

```
┌──────────────┬────────────────────────────────┐
│ Tipo         │ Descrição                      │
├──────────────┼────────────────────────────────┤
│ CLIENTE      │ Cliente final (aluga carros)   │
│ GERENTE      │ Gerente de filial              │
│ ADMIN        │ Administrador do sistema       │
└──────────────┴────────────────────────────────┘
```

---

## 🔐 AUTENTICAÇÃO

### 1. Obter Token JWT

**Método:** `POST /usuarios/login`

**Body:**
```json
{
  "email": "cliente@example.com",
  "senha": "sua_senha_segura"
}
```

**Resposta (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-usuario",
    "email": "cliente@example.com",
    "nome": "João Silva",
    "tipo": "CLIENTE",
    "criado_em": "2026-05-01T10:00:00Z"
  }
}
```

**Resposta (401 Unauthorized):**
```json
{
  "erro": "Credenciais inválidas."
}
```

### 2. Usar Token em Requisições

Adicione o header `Authorization` em TODAS as requisições autenticadas:

```bash
curl -X GET https://api.driveconnect.com.br/filiais \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Token expira em:** 24 horas

### 3. Registrar Novo Usuário

**Método:** `POST /usuarios/registrar`

**Body:**
```json
{
  "email": "novo@example.com",
  "senha": "SenhaForte123!",
  "nome_completo": "Maria Silva",
  "cpf": "123.456.789-10"
}
```

**Resposta (201 Created):**
```json
{
  "id": "uuid-novo-usuario",
  "email": "novo@example.com",
  "nome_completo": "Maria Silva",
  "tipo": "CLIENTE"
}
```

### 4. Recuperar Senha

**Passo 1: Solicitar recuperação**
```
POST /usuarios/esqueci-senha
Body: { "email": "cliente@example.com" }
```

**Passo 2: Redefinir com token**
```
POST /usuarios/redefinir-senha
Body: { 
  "token": "token_enviado_por_email",
  "nova_senha": "NovaSenha123!"
}
```

---

## 🌐 ENDPOINTS POR MÓDULO

### ✅ AUTENTICAÇÃO & USUÁRIOS

#### 1️⃣ Login

```
POST /usuarios/login
```

**Autenticação:** Não requer  
**Body:**
```json
{
  "email": "string",
  "senha": "string"
}
```

**Resposta:** 200 OK com token

---

#### 2️⃣ Registrar Novo Usuário

```
POST /usuarios/registrar
```

**Autenticação:** Não requer  
**Body:**
```json
{
  "email": "string",
  "senha": "string (min 8 chars)",
  "nome_completo": "string",
  "cpf": "string (formato: XXX.XXX.XXX-XX)"
}
```

**Resposta:** 201 Created

---

#### 3️⃣ Recuperar Senha (Passo 1)

```
POST /usuarios/esqueci-senha
```

**Body:**
```json
{
  "email": "string"
}
```

**Resposta:** 200 OK
```json
{
  "mensagem": "Instruções enviadas para o e-mail."
}
```

---

#### 4️⃣ Redefinir Senha (Passo 2)

```
POST /usuarios/redefinir-senha
```

**Body:**
```json
{
  "token": "string (token do email)",
  "nova_senha": "string"
}
```

**Resposta:** 200 OK

---

#### 5️⃣ Meu Perfil (CLIENTE)

```
GET /usuarios/meu-perfil
```

**Autenticação:** ✅ Requer (CLIENTE)  
**Resposta:** 200 OK
```json
{
  "id": "uuid",
  "nome_completo": "João Silva",
  "email": "joao@example.com",
  "cpf": "123.456.789-10",
  "telefone": "+5511987654321",
  "data_criacao": "2026-01-15T10:00:00Z",
  "total_reservas": 5,
  "foto_perfil_url": "https://..."
}
```

---

#### 6️⃣ Atualizar Meu Perfil

```
PUT /usuarios/meu-perfil
```

**Autenticação:** ✅ Requer (CLIENTE)  
**Body:**
```json
{
  "nome_completo": "João Silva Updated",
  "telefone": "+5511987654321",
  "foto_perfil": "base64_ou_url"
}
```

**Resposta:** 200 OK

---

#### 7️⃣ Alterar Senha

```
POST /usuarios/alterar-senha
```

**Autenticação:** ✅ Requer  
**Body:**
```json
{
  "senha_atual": "string",
  "nova_senha": "string"
}
```

**Resposta:** 200 OK

---

### 🏢 FILIAIS

#### 1️⃣ Listar Todas as Filiais

```
GET /filiais
```

**Autenticação:** ✅ Requer  
**Query Params:** Nenhum  
**Resposta:** 200 OK
```json
[
  {
    "id": "uuid-filial-1",
    "nome": "SP Centro",
    "cidade": "São Paulo",
    "uf": "SP",
    "endereco": "Av. Paulista, 1000 - Bela Vista",
    "telefone": "(11) 3000-1000",
    "horario": "08:00-18:00",
    "ativo": true
  },
  {
    "id": "uuid-filial-2",
    "nome": "RJ Copacabana",
    "cidade": "Rio de Janeiro",
    "uf": "RJ",
    "endereco": "Av. Atlântica, 2000",
    "telefone": "(21) 3000-2000",
    "horario": "08:00-20:00",
    "ativo": true
  }
]
```

---

#### 2️⃣ Detalhar Filial

```
GET /filiais/:id
```

**Autenticação:** ✅ Requer  
**Resposta:** 200 OK
```json
{
  "id": "uuid-filial-1",
  "nome": "SP Centro",
  "cidade": "São Paulo",
  "uf": "SP",
  "endereco": "Av. Paulista, 1000",
  "numero": "1000",
  "bairro": "Bela Vista",
  "cep": "01310-100",
  "complemento": "Apto 1001",
  "telefone": "(11) 3000-1000",
  "email": "spcentro@driveconnect.com.br",
  "horario": "08:00-18:00",
  "ativo": true,
  "total_veiculos": 45,
  "veiculos_disponiveis": 38
}
```

---

#### 3️⃣ Criar Filial

```
POST /filiais
```

**Autenticação:** ✅ Requer (ADMIN)  
**Body:**
```json
{
  "nome": "Nova Filial",
  "cidade": "Brasília",
  "uf": "DF",
  "cep": "70040-902",
  "rua": "SCS Bloco B",
  "numero": "400",
  "bairro": "Asa Sul",
  "complemento": "Próximo ao Shopping",
  "telefone": "(61) 3000-3000",
  "email": "brasilia@driveconnect.com.br"
}
```

**Resposta:** 201 Created

---

#### 4️⃣ Atualizar Filial

```
PUT /filiais/:id
```

**Autenticação:** ✅ Requer (ADMIN)  
**Body:** (mesmos campos do POST, opcionais)

**Resposta:** 200 OK

---

#### 5️⃣ Desativar Filial

```
DELETE /filiais/:id
```

**Autenticação:** ✅ Requer (ADMIN)  
**Resposta:** 200 OK
```json
{
  "mensagem": "Filial desativada com sucesso."
}
```

---

### 🚗 VEÍCULOS

#### 1️⃣ Listar Veículos

```
GET /veiculos
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Query Params:**
- `filial_id` (opcional): Filtrar por filial
- `status` (opcional): DISPONIVEL, EM_USO, MANUTENCAO, DESCARTADO
- `modelo_id` (opcional): Filtrar por modelo

**Resposta:** 200 OK
```json
[
  {
    "id": "uuid-veiculo",
    "placa": "ABC-1234",
    "modelo": "Civic",
    "marca": "Honda",
    "categoria": "Sedan",
    "ano": 2024,
    "cor": "Prata",
    "filial": "SP Centro",
    "status": "DISPONIVEL",
    "kilometragem": 15000,
    "preco_diaria": 150.00,
    "imagem_url": "https://...",
    "itens": ["Ar condicionado", "Direção elétrica"]
  }
]
```

---

#### 2️⃣ Listar Veículos Disponíveis

```
GET /veiculos/disponiveis
```

**Autenticação:** ✅ Requer (CLIENTE, GERENTE, ADMIN)  
**Query Params:**
- `data_inicio` (obrigatório): YYYY-MM-DD
- `data_fim` (obrigatório): YYYY-MM-DD
- `filial_id` (opcional): UUID
- `categoria` (opcional): Sedan, SUV, Hatch, etc

**Resposta:** 200 OK
```json
[
  {
    "id": "uuid-veiculo",
    "placa": "ABC-1234",
    "modelo": "Civic",
    "marca": "Honda",
    "categoria": "Sedan",
    "ano": 2024,
    "preco_diaria": 150.00,
    "status": "DISPONIVEL"
  }
]
```

---

#### 3️⃣ Buscar Veículo Específico

```
GET /veiculos/:id
```

**Resposta:** 200 OK

---

#### 4️⃣ Registrar Novo Veículo

```
POST /veiculos
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Content-Type:** `multipart/form-data`  
**Fields:**
- `modelo_id` (string, obrigatório)
- `filial_id` (string, obrigatório)
- `placa` (string, obrigatório)
- `ano` (number, obrigatório)
- `cor` (string, obrigatório)
- `status` (string, obrigatório): DISPONIVEL, EM_USO, MANUTENCAO
- `preco_diaria` (number, opcional)
- `itens_ids` (array de strings, opcional)
- `imagem` (file, opcional)

**Exemplo com cURL:**
```bash
curl -X POST https://api.driveconnect.com.br/veiculos \
  -H "Authorization: Bearer $TOKEN" \
  -F "modelo_id=123" \
  -F "filial_id=uuid-filial" \
  -F "placa=ABC-1234" \
  -F "ano=2024" \
  -F "cor=Prata" \
  -F "status=DISPONIVEL" \
  -F "imagem=@caminho/para/foto.jpg"
```

**Resposta:** 201 Created

---

#### 5️⃣ Atualizar Veículo

```
PUT /veiculos/:id
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Body:** (mesmos campos do POST, opcionais)

**Resposta:** 200 OK

---

#### 6️⃣ Atualizar Status do Veículo

```
PATCH /veiculos/:id/status
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Body:**
```json
{
  "status": "MANUTENCAO",
  "motivo": "Revisão de óleo"
}
```

**Resposta:** 200 OK

---

#### 7️⃣ Deletar Veículo

```
DELETE /veiculos/:id
```

**Autenticação:** ✅ Requer (ADMIN)  
**Resposta:** 200 OK

---

### 🏷️ MODELOS

#### 1️⃣ Listar Modelos

```
GET /modelos
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Query Params:**
- `tipo_carro_id` (opcional): Filtrar por tipo

**Resposta:** 200 OK
```json
[
  {
    "id": "uuid-modelo",
    "nome": "Civic",
    "marca": "Honda",
    "categoria": "Sedan",
    "tipo_carro_id": "uuid-tipo",
    "ano_fabricacao_min": 2020,
    "ano_fabricacao_max": 2024,
    "passageiros": 5,
    "bagagem_litros": 506,
    "velocidade_maxima": 200,
    "combustivel": "Gasolina",
    "cambio": "Automático"
  }
]
```

---

#### 2️⃣ Listar Modelos Disponíveis

```
GET /modelos/disponiveis
```

**Autenticação:** ✅ Requer  
**Query Params:**
- `data_inicio` (obrigatório): YYYY-MM-DD
- `data_fim` (obrigatório): YYYY-MM-DD
- `filial_id` (opcional): UUID

**Resposta:** 200 OK
```json
[
  {
    "id": "uuid-modelo",
    "nome": "Civic",
    "marca": "Honda",
    "categoria": "Sedan",
    "preco_base": 150.00,
    "veiculos_disponiveis": 3
  }
]
```

---

#### 3️⃣ Buscar Modelo

```
GET /modelos/:id
```

**Resposta:** 200 OK

---

#### 4️⃣ Criar Modelo

```
POST /modelos
```

**Autenticação:** ✅ Requer (ADMIN)  
**Body:**
```json
{
  "nome": "Civic",
  "marca": "Honda",
  "categoria": "Sedan",
  "tipo_carro_id": "uuid",
  "ano_fabricacao_min": 2020,
  "ano_fabricacao_max": 2024,
  "passageiros": 5,
  "bagagem_litros": 506,
  "velocidade_maxima": 200,
  "combustivel": "Gasolina",
  "cambio": "Automático"
}
```

**Resposta:** 201 Created

---

#### 5️⃣ Atualizar Modelo

```
PUT /modelos/:id
```

**Resposta:** 200 OK

---

#### 6️⃣ Deletar Modelo

```
DELETE /modelos/:id
```

**Resposta:** 200 OK

---

### 📅 RESERVAS

#### 1️⃣ Verificar Disponibilidade

```
GET /reservas/disponibilidade
```

**Autenticação:** ✅ Requer  
**Query Params:**
- `modelo_id` (obrigatório): number
- `filial_id` (obrigatório): string (UUID)
- `data_inicio` (obrigatório): YYYY-MM-DD
- `data_fim` (obrigatório): YYYY-MM-DD

**Resposta:** 200 OK
```json
{
  "disponivel": true,
  "preco_total": 300.00,
  "veiculo_id": "uuid-veiculo"
}
```

---

#### 2️⃣ Criar Reserva

```
POST /reservas
```

**Autenticação:** ✅ Requer (CLIENTE, GERENTE, ADMIN)  
**Body:**
```json
{
  "veiculo_id": "uuid-veiculo",
  "filial_retirada_id": "uuid-filial-1",
  "filial_devolucao_id": "uuid-filial-1",
  "data_inicio": "2026-05-16",
  "data_fim": "2026-05-18",
  "plano_seguro_id": "uuid-seguro (opcional)",
  "metodo_pagamento": "INFINITEPAY",
  "cliente_id": "uuid-cliente (requerido se gerente)"
}
```

**Resposta:** 201 Created
```json
{
  "id": "uuid-reserva",
  "numero_reserva": "RES-20260516-001",
  "cliente_id": "uuid-cliente",
  "veiculo_id": "uuid-veiculo",
  "status": "PENDENTE_PAGAMENTO",
  "data_inicio": "2026-05-16",
  "data_fim": "2026-05-18",
  "valor_aluguel": 300.00,
  "valor_seguro": 50.00,
  "valor_total": 350.00,
  "link_pagamento": "https://infinitepay.com.br/checkout/abc123xyz",
  "criada_em": "2026-05-15T10:30:00Z"
}
```

---

#### 3️⃣ Listar Minhas Reservas

```
GET /reservas/minhas
```

**Autenticação:** ✅ Requer (CLIENTE)  
**Resposta:** 200 OK
```json
[
  {
    "id": "uuid-reserva",
    "numero_reserva": "RES-20260516-001",
    "veiculo": "Honda Civic (ABC-1234)",
    "filial_retirada": "SP Centro",
    "filial_devolucao": "SP Centro",
    "data_inicio": "2026-05-16",
    "data_fim": "2026-05-18",
    "status": "RESERVADA",
    "valor_total": 350.00,
    "criada_em": "2026-05-15T10:30:00Z"
  }
]
```

---

#### 4️⃣ Consultar Reserva

```
GET /reservas/:id
```

**Autenticação:** ✅ Requer  
**Resposta:** 200 OK
```json
{
  "id": "uuid-reserva",
  "numero_reserva": "RES-20260516-001",
  "cliente": {
    "id": "uuid-cliente",
    "nome": "João Silva",
    "email": "joao@example.com"
  },
  "veiculo": {
    "id": "uuid-veiculo",
    "placa": "ABC-1234",
    "modelo": "Honda Civic",
    "categoria": "Sedan"
  },
  "filial_retirada": "SP Centro",
  "filial_devolucao": "SP Centro",
  "data_inicio": "2026-05-16",
  "data_fim": "2026-05-18",
  "status": "RESERVADA",
  "valor_aluguel": 300.00,
  "valor_seguro": 50.00,
  "valor_total": 350.00,
  "status_pagamento": "CONFIRMADO",
  "data_pagamento": "2026-05-15T14:00:00Z"
}
```

---

#### 5️⃣ Atualizar Reserva

```
PUT /reservas/:id
```

**Autenticação:** ✅ Requer (CLIENTE, GERENTE, ADMIN)  
**Body:** (campos opcionais para atualizar)

**Resposta:** 200 OK

---

#### 6️⃣ Estender Reserva

```
POST /reservas/:id/estender
```

**Autenticação:** ✅ Requer (CLIENTE)  
**Body:**
```json
{
  "nova_data_fim": "2026-05-20"
}
```

**Resposta:** 200 OK
```json
{
  "mensagem": "Reserva estendida com sucesso",
  "nova_data_fim": "2026-05-20",
  "valor_adicional": 150.00,
  "valor_total_novo": 500.00
}
```

---

#### 7️⃣ Cancelar Reserva

```
DELETE /reservas/:id
```

**Autenticação:** ✅ Requer (CLIENTE, GERENTE, ADMIN)  
**Body:**
```json
{
  "motivo": "Motivo do cancelamento (opcional)"
}
```

**Resposta:** 200 OK
```json
{
  "mensagem": "Reserva cancelada com sucesso"
}
```

---

### 💳 PAGAMENTO

#### 1️⃣ Iniciar Pagamento

```
POST /pagamento/iniciar
```

**Autenticação:** ✅ Requer  
**Body:**
```json
{
  "modelo_id": "uuid",
  "filial_retirada_id": "uuid",
  "filial_devolucao_id": "uuid",
  "data_inicio": "2026-05-16",
  "data_fim": "2026-05-18",
  "cliente_id": "uuid",
  "plano_seguro_id": "uuid (opcional)",
  "metodo_pagamento": "INFINITEPAY"
}
```

**Resposta:** 201 Created
```json
{
  "reserva_id": "uuid-reserva",
  "link_pagamento": "https://infinitepay.com.br/checkout/abc123xyz",
  "valor_aluguel": 300.00,
  "valor_seguro": 50.00,
  "valor_total": 350.00
}
```

---

#### 2️⃣ Webhook de Pagamento (InfinitePay → Nossa API)

```
POST /pagamento/webhook
```

**Autenticação:** ⚠️ Assinado por InfinitePay  
**Body:**
```json
{
  "order_nsu": "uuid-reserva",
  "transaction_nsu": "trans-12345",
  "status": "APPROVED",
  "invoice_slug": "invoice-123",
  "capture_method": "automatic",
  "receipt_url": "https://..."
}
```

**Resposta:** 200 OK
```json
{
  "success": true,
  "message": null
}
```

---

#### 3️⃣ Consultar Status de Pagamento

```
GET /pagamento/status/:reservaId
```

**Autenticação:** ✅ Requer  
**Resposta:** 200 OK
```json
{
  "id": "uuid-reserva",
  "status": "RESERVADA",
  "metodo_pagamento": "INFINITEPAY",
  "status_pagamento": "CONFIRMADO",
  "data_pagamento": "2026-05-15T14:00:00Z",
  "comprovante_url": "https://..."
}
```

---

### 💬 WHATSAPP

#### 1️⃣ Webhook de Mensagens Recebidas

```
POST /whatsapp/webhook
GET /whatsapp/webhook (verificação)
```

**Autenticação:** ⚠️ Verificação de assinatura

**Enviado por Meta (WhatsApp):**
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
                "id": "wamid.ABC...",
                "timestamp": "1621884262",
                "type": "text",
                "text": {
                  "body": "Quero alugar um carro"
                }
              }
            ]
          }
        }
      ]
    }
  ]
}
```

---

#### 2️⃣ Enviar Mensagem WhatsApp

```
POST /whatsapp/enviar
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Body:**
```json
{
  "telefone": "5511987654321",
  "mensagem": "Sua reserva foi confirmada!"
}
```

**Resposta:** 200 OK
```json
{
  "mensagem_id": "wamid.ABC...",
  "status": "enviada"
}
```

---

#### 3️⃣ Listar Conversas

```
GET /whatsapp/conversas
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Resposta:** 200 OK
```json
[
  {
    "id": "uuid-conversa",
    "telefone": "5511987654321",
    "cliente_nome": "João Silva",
    "ultima_mensagem": "Quero alugar um carro",
    "data_ultima_mensagem": "2026-05-15T14:30:00Z",
    "status": "ativa"
  }
]
```

---

#### 4️⃣ Listar Mensagens da Conversa

```
GET /whatsapp/conversas/:id/mensagens
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Resposta:** 200 OK
```json
[
  {
    "id": "msg-1",
    "de": "cliente",
    "mensagem": "Quero alugar um carro",
    "data": "2026-05-15T14:30:00Z"
  },
  {
    "id": "msg-2",
    "de": "sistema",
    "mensagem": "Encontrei 3 carros disponíveis...",
    "data": "2026-05-15T14:31:00Z"
  }
]
```

---

### 🔔 NOTIFICAÇÕES

#### 1️⃣ Registrar Token FCM (Push Notifications)

```
POST /notificacoes/token
```

**Autenticação:** ✅ Requer  
**Body:**
```json
{
  "token": "token_fcm_do_firebase",
  "plataforma": "iOS ou Android",
  "deviceId": "id_do_dispositivo"
}
```

**Resposta:** 200 OK
```json
{
  "ok": true
}
```

---

#### 2️⃣ Remover Token FCM

```
DELETE /notificacoes/token
```

**Autenticação:** ✅ Requer  
**Body:**
```json
{
  "token": "token_fcm_do_firebase"
}
```

**Resposta:** 200 OK

---

### 📊 RELATÓRIOS

#### 1️⃣ Relatório de Reservas

```
GET /relatorios/reservas
```

**Autenticação:** ✅ Requer (GERENTE, ADMIN)  
**Query Params:**
- `data_inicio` (opcional): YYYY-MM-DD
- `data_fim` (opcional): YYYY-MM-DD
- `filial_id` (opcional): UUID
- `status` (opcional): PENDENTE_PAGAMENTO, RESERVADA, ATIVA, CONCLUIDA

**Resposta:** 200 OK
```json
{
  "total_reservas": 150,
  "valor_total": 45000.00,
  "reservas_concluidas": 120,
  "reservas_canceladas": 10,
  "receita_media": 300.00,
  "detalhes": [...]
}
```

---

#### 2️⃣ Relatório Financeiro

```
GET /relatorios/financeiro
```

**Autenticação:** ✅ Requer (ADMIN)  
**Query Params:**
- `mes` (opcional): MM (01-12)
- `ano` (opcional): YYYY
- `filial_id` (opcional): UUID

**Resposta:** 200 OK

---

---

## 🔢 CÓDIGOS DE STATUS HTTP

| Código | Significado | Exemplo |
|--------|-------------|---------|
| **200** | OK | Requisição bem-sucedida |
| **201** | Created | Recurso criado com sucesso |
| **204** | No Content | Sucesso, sem corpo na resposta |
| **400** | Bad Request | Dados inválidos ou faltando |
| **401** | Unauthorized | Token inválido ou ausente |
| **403** | Forbidden | Sem permissão para acessar |
| **404** | Not Found | Recurso não encontrado |
| **409** | Conflict | Conflito (ex: datas conflitantes) |
| **429** | Too Many Requests | Rate limit excedido |
| **500** | Internal Server Error | Erro no servidor |

---

## ⚠️ TRATAMENTO DE ERROS

### Exemplo de Erro 400 (Bad Request)

```json
{
  "erro": "Parâmetros obrigatórios ausentes."
}
```

### Exemplo de Erro 401 (Unauthorized)

```json
{
  "erro": "Credenciais inválidas."
}
```

### Exemplo de Erro 403 (Forbidden)

```json
{
  "erro": "Gerente só pode criar reserva para sua própria filial."
}
```

### Exemplo de Erro 404 (Not Found)

```json
{
  "erro": "Veículo não encontrado."
}
```

### Exemplo de Erro 409 (Conflict)

```json
{
  "erro": "Nenhum veículo disponível para o período solicitado."
}
```

---

## 🚦 RATE LIMITING

**Limite:** 120 requisições por minuto (por IP)  
**WhatsApp:** 5 requisições por minuto (por número de telefone)

**Headers de Resposta:**
```
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 89
X-RateLimit-Reset: 1621884360
```

**Se exceder o limite (429):**
```json
{
  "erro": "Rate limit exceeded. Tente novamente em alguns segundos."
}
```

---

## 📝 EXEMPLOS DE REQUISIÇÃO

### Exemplo 1: Login

```bash
curl -X POST https://api.driveconnect.com.br/usuarios/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "cliente@example.com",
    "senha": "SenhaForte123!"
  }'
```

**Resposta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-usuario",
    "email": "cliente@example.com",
    "nome": "João Silva",
    "tipo": "CLIENTE"
  }
}
```

---

### Exemplo 2: Verificar Disponibilidade

```bash
TOKEN="seu_token_jwt_aqui"

curl -X GET "https://api.driveconnect.com.br/reservas/disponibilidade?modelo_id=1&filial_id=uuid-sp&data_inicio=2026-05-16&data_fim=2026-05-18" \
  -H "Authorization: Bearer $TOKEN"
```

**Resposta:**
```json
{
  "disponivel": true,
  "preco_total": 300.00,
  "veiculo_id": "uuid-honda-civic"
}
```

---

### Exemplo 3: Criar Reserva

```bash
TOKEN="seu_token_jwt_aqui"

curl -X POST https://api.driveconnect.com.br/reservas \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "veiculo_id": "uuid-honda-civic",
    "filial_retirada_id": "uuid-sp-centro",
    "filial_devolucao_id": "uuid-sp-centro",
    "data_inicio": "2026-05-16",
    "data_fim": "2026-05-18",
    "metodo_pagamento": "INFINITEPAY"
  }'
```

**Resposta:**
```json
{
  "id": "uuid-reserva-123",
  "numero_reserva": "RES-20260516-001",
  "status": "PENDENTE_PAGAMENTO",
  "valor_total": 350.00,
  "link_pagamento": "https://infinitepay.com.br/checkout/abc123xyz"
}
```

---

### Exemplo 4: Upload de Veículo

```bash
TOKEN="seu_token_jwt_aqui"

curl -X POST https://api.driveconnect.com.br/veiculos \
  -H "Authorization: Bearer $TOKEN" \
  -F "modelo_id=1" \
  -F "filial_id=uuid-sp-centro" \
  -F "placa=ABC-1234" \
  -F "ano=2024" \
  -F "cor=Prata" \
  -F "status=DISPONIVEL" \
  -F "imagem=@/caminho/para/foto.jpg"
```

**Resposta:**
```json
{
  "id": "uuid-novo-veiculo",
  "placa": "ABC-1234",
  "modelo": "Civic",
  "status": "DISPONIVEL"
}
```

---

### Exemplo 5: Listar Minhas Reservas

```bash
TOKEN="seu_token_jwt_aqui"

curl -X GET https://api.driveconnect.com.br/reservas/minhas \
  -H "Authorization: Bearer $TOKEN"
```

**Resposta:**
```json
[
  {
    "id": "uuid-reserva-1",
    "numero_reserva": "RES-20260516-001",
    "veiculo": "Honda Civic (ABC-1234)",
    "status": "RESERVADA",
    "data_inicio": "2026-05-16",
    "data_fim": "2026-05-18",
    "valor_total": 350.00
  },
  {
    "id": "uuid-reserva-2",
    "numero_reserva": "RES-20260510-002",
    "veiculo": "Toyota Corolla (XYZ-5678)",
    "status": "CONCLUIDA",
    "data_inicio": "2026-05-10",
    "data_fim": "2026-05-12",
    "valor_total": 320.00
  }
]
```

---

### Exemplo 6: Enviar Mensagem WhatsApp

```bash
TOKEN="seu_token_jwt_aqui"

curl -X POST https://api.driveconnect.com.br/whatsapp/enviar \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "telefone": "5511987654321",
    "mensagem": "Sua reserva foi confirmada! 🎉"
  }'
```

**Resposta:**
```json
{
  "mensagem_id": "wamid.HBEUGk...",
  "status": "enviada"
}
```

---

## 🔑 CHEAT SHEET

### Headers Obrigatórios (Requisições Autenticadas)

```bash
Authorization: Bearer <seu_token_jwt>
Content-Type: application/json
```

### URLs Base por Ambiente

```
Produção: https://api.driveconnect.com.br
Staging:  https://staging-api.driveconnect.com.br
Local:    http://localhost:3000
```

### Status Possíveis de Reserva

```
PENDENTE_PAGAMENTO → Reserva criada, aguardando pagamento
RESERVADA          → Pagamento confirmado
ATIVA              → Cliente pegou o carro
CONCLUIDA          → Carro foi devolvido
CANCELADA          → Reserva cancelada
```

### Tipos de Erro Comuns

```
400: Dados inválidos (validação)
401: Token inválido ou expirado
403: Usuário sem permissão
404: Recurso não encontrado
409: Conflito (ex: datas conflitantes)
429: Rate limit excedido
500: Erro interno
```

---

## 📚 PRÓXIMAS CONSULTAS

- [Documentação da Integração IA](EXPLICACAO_INTEGRACAO_COMPLETA.md)
- [Guia de Desenvolvimento](SETUP_AI_AGENT.sh)
- [Status do Sistema](STATUS_AI_AGENT.md)

---

**Última atualização:** 24/05/2026  
**Versão:** 2.0  
**Status:** ✅ Produção
