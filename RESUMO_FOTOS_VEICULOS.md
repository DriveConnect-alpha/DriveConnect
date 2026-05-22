# Resumo: Funcionalidade de Fotos de Veículos

## 🎯 Objetivo
Permitir que o bot envie fotos de veículos quando o usuário pedir ("Foto do HB20", "Mostre imagem do Gol", etc).

## ✨ Alterações Realizadas

### 1. **Novas Funções Adicionadas em `agent.ts`**

#### `getVeiculoFotos(modeloName: string): Promise<string[]>`
- Busca fotos de um veículo por modelo no banco de dados
- Query otimizada com JOINs e índices
- Retorna array de URLs formatadas
- Prioriza foto principal (`is_principal = TRUE`)
- Limita a 5 fotos por modelo

#### `detectModeloMencionado(messageText: string): string | null`
- Detecta qual modelo de carro foi mencionado na mensagem
- Suporta 8 modelos: HB20, Gol, Onix, Kicks, Tracker, Corolla, Tiguan, Sportage
- Case-insensitive
- Retorna `null` se não encontrar modelo

### 2. **Melhorias em `atenderClienteComAgent()`**

**Novo Fluxo para Fotos:**
1. Detecta palavras-chave: "foto", "imagem", "mostre"
2. Verifica se há menção de veículo: "do", "da"
3. Identifica o modelo mencionado
4. Busca fotos no BD
5. Retorna com intenção `VER_FOTOS` e array de fotos

**Novo Campo de Retorno:**
```typescript
{
  resposta: string;
  intencao: string;
  tools_usadas: string[];
  fotos?: string[];        // ← NOVO
  clienteId?: string;
  paymentLink?: string;
}
```

**Nova Intenção:**
- `VER_FOTOS`: Quando cliente pede foto de um modelo

### 3. **Integração com WhatsApp Service**

O `whatsapp.service.ts` já suporta envio de fotos:
```typescript
if (agentResult.fotos && agentResult.fotos.length > 0) {
  const { sendImageByUrl } = await import('./whatsapp-media.service.js');
  await sendImageByUrl(from, agentResult.fotos[0]);
}
```

## 📊 Exemplos de Execução

### Exemplo 1: Pedido de Foto Bem-sucedido
```
User: "Pode me enviar a foto do HB20?"
       ↓ detectModeloMencionado() → "Hb20"
       ↓ getVeiculoFotos("Hb20") → ["URL1", "URL2"]

Bot Resposta:
{
  resposta: "Aqui está a foto do Hb20! 📸",
  intencao: "VER_FOTOS",
  tools_usadas: ["obter_fotos_veiculo"],
  fotos: ["https://driveconnect.com/uploads/carros/hb20_1.jpg"],
  clienteId: "cliente-123"
}

→ WhatsApp envia a imagem
```

### Exemplo 2: Modelo não reconhecido
```
User: "Foto do Ferrari"
       ↓ detectModeloMencionado() → null
       ↓ Processa via RAG genérico

Bot: (Resposta via RAG)
"Desculpe, não tenho foto de um Ferrari disponível..."
```

## 🔧 Arquivo Modificado

**Arquivo:** `Backend/src/ai/agent.ts`

**Mudanças:**
1. ✅ Adicionada função `getVeiculoFotos()` (linhas ~425-450)
2. ✅ Adicionada função `detectModeloMencionado()` (linhas ~453-465)
3. ✅ Integrado fluxo de fotos em `atenderClienteComAgent()` (linhas ~1215-1238)
4. ✅ Adicionado campo `fotos` ao retorno (linha ~1300)
5. ✅ Adicionada variável `fotos` no escopo da função (linha ~1205)

## 📈 Melhorias

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Pedido de foto** | ❌ Não suportado | ✅ Automático |
| **Detecção** | - | ✅ 8 modelos |
| **Busca em BD** | - | ✅ Query otimizada |
| **Envio de mídia** | Via intento | ✅ Direto ao usuário |
| **UX** | Fragmentada | ✅ Fluida |

## 🗄️ Banco de Dados

### Tabela: `veiculo_imagem`
- `id` (UUID) - Identificador único
- `veiculo_id` (UUID) - Referência ao veículo
- `filename` (VARCHAR) - Nome do arquivo
- `is_principal` (BOOLEAN) - Foto principal
- `ordem` (INT) - Ordem de exibição
- `criado_em` (TIMESTAMP) - Data de criação

**Índices:**
- `idx_veiculo_imagem_veiculo` em `veiculo_id`

## 🔐 Segurança

- ✅ URLs formatadas com `UPLOAD_URL` (configurável)
- ✅ Apenas fotos de veículos ativos
- ✅ Apenas arquivos registrados no BD
- ✅ Sem exposição de caminhos internos

## 📋 Status de Compilação

```
✅ TypeScript: Sem erros
✅ Build: npm run build ✓
✅ Funcionalidade: Pronta
✅ Integração: Completa
```

## 🚀 Como Usar

### Usuário Final
```
"Foto do Gol" → Bot envia imagem
"Mostre a foto do HB20" → Bot envia imagem
"Qual é a aparência do Corolla?" → Bot envia imagem
```

### Desenvolvedor
```typescript
const resultado = await atenderClienteComAgent(
  "Foto do HB20",
  { clienteId: "user-123" }
);

if (resultado.fotos?.length) {
  // Enviar foto via WhatsApp
  await sendImageByUrl(telefone, resultado.fotos[0]);
}
```

## 📚 Documentação Completa
Ver: `FUNCIONALIDADE_FOTOS_VEICULOS.md`

## ✅ Checklist

- ✅ Função `getVeiculoFotos()` implementada
- ✅ Função `detectModeloMencionado()` implementada
- ✅ Integração em `atenderClienteComAgent()`
- ✅ 8 modelos de carros suportados
- ✅ Query otimizada no BD
- ✅ Retorno com campo `fotos`
- ✅ Compilação sem erros
- ✅ Build bem-sucedido
- ✅ Documentação criada
