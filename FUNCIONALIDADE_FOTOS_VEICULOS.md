# Funcionalidade de Fotos de Veículos - WhatsApp

## 📸 Visão Geral

O bot agora consegue detectar quando o usuário pede foto de um veículo específico e enviar automaticamente a imagem principal do modelo mencionado via WhatsApp.

## 🎯 Como Funciona

### Detecção de Pedido de Foto

O sistema detecta pedidos como:
- "Foto do Gol"
- "Mostre a foto do HB20"
- "Imagem do Corolla"
- "Pode enviar foto do Tiguan?"
- "Qual é a aparência do Sportage?"

### Fluxo de Processamento

```
Usuario: "Foto do HB20"
  ↓
┌─────────────────────────────────┐
│ atenderClienteComAgent()        │
└──────────────┬──────────────────┘
              ↓
    ┌──────────────────────────┐
    │ Detecta "foto" +        │
    │ "do/da" + modelo?       │
    └──────────┬───────────────┘
            ↓ (sim)
    ┌──────────────────────────┐
    │ detectModeloMencionado() │
    │ Encontra: "HB20"        │
    └──────────┬───────────────┘
            ↓
    ┌──────────────────────────┐
    │ getVeiculoFotos("HB20") │
    │ Busca no BD              │
    └──────────┬───────────────┘
            ↓
    ┌──────────────────────────┐
    │ Encontrou fotos?        │
    │ Sim! 1 imagem           │
    └──────────┬───────────────┘
            ↓
    ┌──────────────────────────┐
    │ Retorna:                │
    │ - resposta: "Aqui..."  │
    │ - intencao: VER_FOTOS  │
    │ - fotos: [URL]          │
    └──────────────────────────┘
            ↓
        Bot envia foto
```

## 🔧 Implementação

### Função: `detectModeloMencionado(messageText)`

Detecta qual modelo de carro foi mencionado na mensagem.

**Modelos suportados:**
- HB20
- Gol
- Onix
- Kicks
- Tracker
- Corolla
- Tiguan
- Sportage

**Retorno:** Nome do modelo ou `null`

```typescript
const modelo = detectModeloMencionado("Quero foto do HB20");
// Retorna: "Hb20"
```

### Função: `getVeiculoFotos(modeloName)`

Busca todas as fotos disponíveis para um modelo de carro no banco de dados.

**Query:**
```sql
SELECT vi.filename
FROM veiculo_imagem vi
JOIN veiculo v ON v.id = vi.veiculo_id
JOIN modelo m ON m.id = v.modelo_id
WHERE m.nome ILIKE $1
  AND vi.filename IS NOT NULL
  AND v.deletado_em IS NULL
  AND v.status != 'MANUTENCAO'
ORDER BY vi.is_principal DESC, vi.ordem ASC
LIMIT 5
```

**Retorno:** Array de URLs das fotos

```typescript
const fotos = await getVeiculoFotos("HB20");
// Retorna: ["https://driveconnect.com/uploads/carros/hb20_1.jpg", ...]
```

### Integração em `atenderClienteComAgent()`

**Lógica:**
1. Verifica se mensagem menciona foto ("foto", "imagem", "mostre")
2. Verifica se menciona um veículo ("do", "da")
3. Detecta qual modelo foi mencionado
4. Busca fotos no BD
5. Se encontrou, retorna com `intencao: 'VER_FOTOS'` e `fotos: [...]`
6. WhatsApp service envia a primeira foto

**Resposta do Bot:**
```
Aqui está a foto do HB20! 📸
[Imagem enviada via WhatsApp]
```

## 📊 Tabela do Banco de Dados

### `veiculo_imagem`
```sql
CREATE TABLE veiculo_imagem (
    id UUID PRIMARY KEY,
    veiculo_id UUID REFERENCES veiculo(id),
    filename VARCHAR(255),           -- ex: "hb20_frente.jpg"
    is_principal BOOLEAN,             -- TRUE = foto que aparece primeiro
    ordem INT,                        -- Ordem de exibição (0=primeira)
    criado_em TIMESTAMP
);
```

## 🔗 Integração com WhatsApp Service

O `whatsapp.service.ts` já suporta envio de fotos:

```typescript
// Quando o bot retorna fotos:
if (agentResult.fotos && agentResult.fotos.length > 0 && agentResult.fotos[0]) {
  const { sendImageByUrl } = await import('./whatsapp-media.service.js');
  void sendImageByUrl(from, agentResult.fotos[0]).catch((err) => {
    console.error('[WhatsApp] Erro ao enviar foto:', err);
  });
}
```

## 📝 Exemplos de Uso

### Exemplo 1: Pedido Simples de Foto
```
User: "Foto do Gol"
Bot: "Aqui está a foto do Gol! 📸"
Bot: [Envia imagem]
```

### Exemplo 2: Pedido com mais contexto
```
User: "Pode me mostrar como é o HB20?"
Bot: "Aqui está a foto do Hb20! 📸"
Bot: [Envia imagem]
```

### Exemplo 3: Sem fotos disponíveis
```
User: "Foto do Lamborghini"
Bot: [Processa via RAG genérico]
Bot: "Desculpe, não tenho foto de um Lamborghini disponível. 
      Gostaria de conhecer nossos modelos disponíveis?"
```

## 🎯 Intenções Detectadas

| Intenção | Quando | Ação |
|----------|--------|------|
| `VER_FOTOS` | Cliente pede foto de um modelo específico | Envia foto do modelo |
| `LISTAR_CARROS` | Cliente pergunta sobre disponibilidade | Lista veículos com preços |
| `AWAITING_CONFIRMATION` | Cliente seleciona um carro | Mostra confirmação |
| `CONFIRMAR_RESERVA` | Cliente confirma | Envia link de pagamento |
| `GENERICO` | Outras perguntas | Processa via RAG |

## ⚙️ Configurações

### Variáveis de Ambiente

```bash
# URL base para fotos (padrão: https://driveconnect.com/uploads/carros)
UPLOAD_URL=https://driveconnect.com/uploads/carros

# Exemplo com CDN:
UPLOAD_URL=https://cdn.driveconnect.com/carros
```

## 📋 Checklist de Implementação

- ✅ Função `detectModeloMencionado()` implementada
- ✅ Função `getVeiculoFotos()` implementada
- ✅ Integração em `atenderClienteComAgent()`
- ✅ Suporte para 8 modelos de carros
- ✅ Busca no BD com query otimizada
- ✅ Retorno de múltiplas fotos
- ✅ Priorização de foto principal (`is_principal`)
- ✅ Compilação TypeScript: ✅ Sem erros
- ✅ Build: ✅ Sucesso

## 🚀 Próximos Passos

1. **Adicionar mais modelos**: Expandir lista de modelos detectáveis
2. **Busca por filial**: Filtrar fotos por unidade
3. **Múltiplas fotos**: Enviar album com todas as fotos
4. **Fotos de interior**: Diferenciar fotos de frente, lado, interior
5. **Recomendação de foto**: Enviar fotos relacionadas ao modelo selecionado

## 🔐 Segurança

- Apenas fotos de veículos ativos (não em manutenção)
- Apenas arquivos registrados no BD
- URLs sanitizadas com `UPLOAD_URL`
- Sem exposição de caminhos do servidor

## 📊 Status

```
✅ Compilação: Sem erros TypeScript
✅ Build: Sucesso npm run build
✅ Funcionalidade: Pronta para uso
✅ Detecção de modelos: 8 modelos
✅ Busca em BD: Otimizada
```
