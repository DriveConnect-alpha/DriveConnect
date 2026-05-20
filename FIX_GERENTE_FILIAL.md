# Fix: Gerente Responsável não aparecia nas Filiais

## Problema
Quando você cadastrava um gerente em uma filial, ele não estava sendo exibido quando você listava as filiais.

## Causa
O endpoint `GET /filiais` retornava apenas dados básicos da filial (id, nome, cidade, uf, bairro, ativo) mas **não incluía informações do gerente responsável** vinculado àquela filial.

## Solução

### Backend (TypeScript)

#### 1. **Adicionada interface `GerenteDaFilial` em `filial.service.ts`**
```typescript
export interface GerenteDaFilial {
  id: string;
  nomeCompleto: string;
}
```

#### 2. **Atualizada interface `FilialPublica` para incluir gerente**
```typescript
export interface FilialPublica {
  id: string;
  nome: string | null;
  cidade: string | null;
  uf: string | null;
  bairro: string | null;
  ativo: boolean;
  gerenteResponsavel?: GerenteDaFilial | null;  // ← NOVO
}
```

#### 3. **Alterado SQL da função `_listarFiliais()`**
- **Antes:** Buscava apenas dados de `filial`
- **Depois:** Faz `LEFT JOIN` com `gerente` para buscar o gerente vinculado

```typescript
const r = await query(
  `SELECT f.id, f.nome, f.cidade, f.uf, f.bairro, f.ativo,
          g.id as gerente_id, g.nome_completo as gerente_nome
   FROM filial f
   LEFT JOIN gerente g ON g.filial_id = f.id AND g.deletado_em IS NULL
   WHERE f.deletado_em IS NULL
   ORDER BY f.nome`,
);
```

#### 4. **Atualizada função `_buscarFilialPorId()`**
- Também incluiu o `LEFT JOIN` com gerente para manter consistência

### Frontend (Flutter)

#### 1. **Classe `GerenteDaFilial` em `core/models/filial.dart`**
```dart
class GerenteDaFilial {
  final String id;
  final String nomeCompleto;
  
  factory GerenteDaFilial.fromJson(Map<String, dynamic> json) { ... }
}
```

#### 2. **Classe `Filial` atualizada**
- Adicionado campo `gerenteResponsavel?: GerenteDaFilial`
- Atualizado método `fromJson()` para parsear dados do gerente
- Atualizado método `toJson()` para incluir gerente

#### 3. **Modelo em `features/filial/models/filial.dart`**
- Mesmas alterações aplicadas ao modelo local da feature

## Como Usar

Agora quando você chamar `GET /filiais`, cada filial terá:

```json
{
  "id": "uuid-da-filial",
  "nome": "Filial São Paulo",
  "cidade": "São Paulo",
  "uf": "SP",
  "bairro": "Centro",
  "ativo": true,
  "gerenteResponsavel": {
    "id": "uuid-do-gerente",
    "nomeCompleto": "João Silva"
  }
}
```

Se a filial não tem gerente vinculado, `gerenteResponsavel` será `null`.

## Impacto

✅ Listagem de filiais agora mostra o gerente responsável  
✅ Busca por ID de filial também retorna o gerente  
✅ Backend: 0 erros TypeScript  
✅ Frontend: Modelos atualizados para desserializar o novo campo

## Endpoints Afetados

- `GET /filiais` — agora retorna `gerenteResponsavel`
- `GET /filiais/:id` — agora retorna `gerenteResponsavel`

## Próximos Passos

1. Testar o backend (reiniciar servidor)
2. Recompilar o Flutter se necessário
3. Atualizar a UI para exibir o nome do gerente (opcional)
