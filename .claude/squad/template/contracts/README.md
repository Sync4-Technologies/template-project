# Contratos

> Esta pasta contém todos os contratos do sistema.
> Nenhuma implementação começa sem contrato definido aqui.

---

## O que é um contrato

Um contrato é a **especificação formal da interface** entre dois componentes.

Contratos garantem que:
- Backend e Frontend podem ser desenvolvidos em paralelo
- Testes podem ser escritos antes da implementação
- Mudanças de interface são explícitas e versionadas

---

## Tipos de Contrato

### APIs REST
- **Formato:** OpenAPI 3.1 (YAML)
- **Nomenclatura:** `[domínio].api.yaml`
- **Exemplo:** `auth.api.yaml`, `orders.api.yaml`

### Schemas de Validação
- **Formato:** JSON Schema ou Zod (TypeScript)
- **Nomenclatura:** `[entidade].schema.json` ou `[entidade].schema.ts`
- **Exemplo:** `user.schema.ts`, `payment.schema.json`

### Interfaces TypeScript
- **Formato:** `.ts` com export de types/interfaces
- **Nomenclatura:** `[domínio].types.ts`
- **Exemplo:** `auth.types.ts`, `order.types.ts`

### Eventos / Mensagens
- **Formato:** JSON Schema ou AsyncAPI
- **Nomenclatura:** `[evento].event.yaml`
- **Exemplo:** `order-created.event.yaml`

---

## Regras de Versionamento

1. Toda alteração de contrato **deve ser versionada**
2. Mudanças breaking → incrementar versão major (v1 → v2)
3. Mudanças não-breaking (adição de campo opcional) → incrementar minor
4. Manter compatibilidade retroativa quando possível
5. Mudança não versionada → **bloqueio de implementação**

---

## Processo de Aprovação

1. Architect cria ou atualiza contrato
2. Tech Lead revisa
3. Tech Lead apresenta ao usuário quando impacto for alto
4. Implementação começa após aprovação

---

## Estrutura Recomendada

```
/contracts
├── README.md              ← este arquivo
├── example.openapi.yaml   ← exemplo de contrato REST
├── auth/
│   ├── auth.api.yaml
│   └── auth.types.ts
├── orders/
│   ├── orders.api.yaml
│   └── orders.schema.ts
└── events/
    └── order-created.event.yaml
```
