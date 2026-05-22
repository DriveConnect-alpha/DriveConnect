# Recurso de Fotos de Veículos via WhatsApp

## 📸 Visão Geral

O bot pode enviar fotos de veículos **quando o cliente pedir explicitamente**:
1. **Cliente pede foto** - "Mostre a foto do Corolla", "Quero ver a foto desse Gol"
2. **Apenas a foto principal** - Uma foto por vez, conforme solicitado
3. **Sem envio automático** - Não envia fotos em listas, apenas quando pedido

## 🛠️ Componentes Implementados

### 1. Nova Tool: `toolObterFotosVeiculo()` (tools.ts)

```typescript
export async function toolObterFotosVeiculo(veiculo_id: string): Promise<ToolResult<FotoVeiculo>>
```

**O que faz:**
- Busca todas as fotos de um veículo no banco de dados
- Retorna URLs das imagens e marca qual é a principal
- Valida se o veículo existe antes de buscar fotos
- Retorna erro se não houver fotos disponíveis

**Resposta:**
```typescript
{
  veiculo_id: string;
  placa: string;
  modelo: string;
  fotos: Array<{
    url: string;
    principal: boolean;
  }>;
}
```

### 2. Novo Serviço: `whatsapp-media.service.ts`

Funções para enviar mídia via WhatsApp Graph API:

**`sendImageByUrl(to, imageUrl, caption?)`**
- Envia uma imagem via WhatsApp
- Suporta legenda opcional
- Retorna ID da mensagem ou null se falhar

**`sendMultipleImages(to, imageUrls, delayMs?)`**
- Envia múltiplas imagens em sequência
- Delay padrão de 500ms entre envios para evitar rate limit
- Retorna array com IDs das mensagens enviadas

**`sendDocument(to, documentUrl, filename, caption?)`**
- Envia documentos/PDFs
- Útil para enviando contratos, cupons, etc

**`sendVideo(to, videoUrl, caption?)`**
- Envia vídeos (para futuro)

### 3. Nova Intenção no Agent: `VER_FOTOS`

Detecção automática quando cliente quer ver fotos:
- Palavras-chave: "foto", "imagem", "picture", "mostrar", "ver", "enviar", "compartilhar"
- Extrai o `veiculo_id` do contexto da conversa
- Chamada automática a `toolObterFotosVeiculo()`

### 4. Integração no WhatsApp Service

Quando o agent executa com sucesso e há fotos:

```typescript
if (agentResult.fotos && agentResult.fotos.length > 0) {
  const { sendMultipleImages } = await import('./whatsapp-media.service.js');
  void sendMultipleImages(from, agentResult.fotos, 1000).catch(...);
}
```

**Fluxo:**
1. Agent detecta intenção `LISTAR_CARROS` ou `VER_FOTOS`
2. Retorna array `fotos: string[]` com URLs
3. WhatsApp service envia cada foto (1 segundo de delay)
4. Cliente recebe as fotos + mensagem de contexto

## 📊 Banco de Dados

As fotos são armazenadas na tabela `veiculo_imagem`:

```sql
CREATE TABLE veiculo_imagem (
  id SERIAL PRIMARY KEY,
  veiculo_id INTEGER NOT NULL,
  filename VARCHAR(255) NOT NULL,  -- URL ou path da imagem
  is_principal BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (veiculo_id) REFERENCES veiculo(id)
);
```

**Queries usadas:**
- Buscar foto principal: `ORDER BY is_principal DESC LIMIT 1`
- Buscar todas as fotos: `ORDER BY is_principal DESC, created_at ASC`

## 🔄 Fluxos de Uso

### Fluxo 1: Cliente pede fotos

```
Cliente: "Tem foto do Gol?"
↓
Agent: Detecta VER_FOTOS
↓
Agent: Extrai veiculo_id do contexto
↓
toolObterFotosVeiculo(veiculo_id)
↓
Retorna: { fotos: ["url1", "url2", "url3"] }
↓
WhatsApp: sendMultipleImages(from, fotos)
↓
Cliente: Recebe 3 imagens do Gol
```

### Fluxo 2: Listagem automática com fotos

```
Cliente: "Quais carros disponíveis em maio?"
↓
Agent: Detecta LISTAR_CARROS
↓
toolListarCarrosDisponiveis(params)
↓
Retorna: [{ modelo: "Gol", imagem_url: "url1" }, ...]
↓
Agent: Responde com listagem (SEM enviar fotos)
↓
Cliente: Vê listagem e diz "Foto do Gol"
↓
Agent: Detecta VER_FOTOS
↓
toolObterFotosVeiculo(veiculo_id)
↓
Retorna: { fotos: [ { url: "url1", principal: true }, ... ] }
↓
Agent: Extrai foto principal e armazena
↓
WhatsApp: sendImageByUrl(from, url1)
↓
Cliente: Recebe 1 foto do Gol
```

### Fluxo 3: Consulta de reserva com foto

```
Cliente: "Qual o status da minha reserva?"
↓
Agent: Detecta RASTREAR_RESERVA
↓
toolObterReserva(reserva_id)
↓
Retorna: { imagem_url: "url_do_veiculo" }
↓
(Atual) Resposta com info da reserva
(Futuro) Enviar foto do veículo também
```

## 🎯 Variáveis de Ambiente

Não há variáveis novas necessárias. Usa as mesmas do WhatsApp:
- `WHATSAPP_GRAPH_API_VERSION` (padrão: v19.0)
- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_TIMEOUT_MS` (padrão: 10000)

## ⚙️ Configuração Recomendada

No `.env`:
```env
# WhatsApp - existente
WHATSAPP_GRAPH_API_VERSION=v19.0
WHATSAPP_ACCESS_TOKEN=seu_token
WHATSAPP_PHONE_NUMBER_ID=seu_phone_id

# Agent - ativar fotos
WHATSAPP_USE_AGENT=true

# Opcional: ajustar delay entre fotos
# WHATSAPP_MEDIA_DELAY_MS=1000
```

## 🧪 Testando

### Via Terminal

```bash
# Build
npm run build

# Testes unitários
npm test -- tests/unit/ai.test.ts

# Executar agent
npx ts-node Backend/src/ai/agent.example.ts
```

### Via WhatsApp

1. Enviar: "Mostre fotos do Gol"
2. Receber resposta do agent + fotos

3. Enviar: "Carros SUV em maio"
4. Receber listagem + fotos dos SUVs

## 📝 Logs

Quando as fotos são enviadas, você vê:

```
[WhatsApp] Imagem enviada para +55... | ID: wamid.xxx
[WhatsApp] Imagem enviada para +55... | ID: wamid.xxx
[WhatsApp] Imagem enviada para +55... | ID: wamid.xxx
```

Se houver erro:
```
[WhatsApp] Erro ao enviar fotos: Error: Network timeout
```

## 🚀 Próximas Melhorias

1. **Galeria de fotos** - Cliente pode rolar entre fotos com botões
2. **Vídeos de produto** - Enviar vídeos de apresentação do carro
3. **Filtro de qualidade** - Enviar apenas fotos de boa qualidade
4. **Thumbnail inteligente** - Criar miniaturas automáticas
5. **Cache de URLs** - Cachear URLs para evitar queries ao banco
6. **Análise de imagens** - Usar AI para descrever fotos automaticamente

## 🔒 Segurança

- URLs são validadas (não há injeção SQL)
- Delay entre envios evita rate limiting
- Timeouts de 10s para não travar conversas
- Erros são logados mas não expõem dados sensíveis

## 📚 Referências

- [WhatsApp Graph API - Image Messages](https://developers.facebook.com/docs/whatsapp/cloud-api/reference/messages#image-object)
- [WhatsApp Media Types](https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media)
- [Rate Limiting](https://developers.facebook.com/docs/whatsapp/cloud-api/rate-limiting)
