---
name: squad-audit
description: Audit profundo de code + security sobre o repo (ou área), com varredura multi-passada em paralelo e verificação adversarial dos achados. Use periodicamente (mensal, pré-release major) ou quando houver suspeita de qualidade — formaliza o "audit code / audit security" manual. Achados viram cards priorizados no TASK_BOARD.
---

# Skill — Squad Audit (code + security)

Audit ≠ review de PR: review caça no diff; audit caça no **sistema como está**. Read-only — achados viram cards, nunca correção durante o audit.

## Quando usar

- Cadência: mensal em Production Mode, ou antes de release major
- Suspeita de qualidade acumulada (bugs em produção repetidos, review interno sem achados por várias sessões)
- Onboarding de codebase legado na squad

## Quando NÃO usar

- Para revisar um PR/diff — isso é o fluxo normal (Code Reviewer)
- Logo após outro audit sem mudança relevante — audit sem delta é custo sem sinal

## Passos (Tech Lead orquestra)

### 1. Escopo + baseline

- Definir área: repo inteiro ou módulos (auth, billing, runtime...). Repo grande → priorizar por risco (dados pessoais, dinheiro, superfície externa)
- Baseline: achados do último audit (cards `AUD-*` no TASK_BOARD / LESSONS). Sem baseline = primeiro audit, registrar como marco

### 2. Varredura paralela (spawns por dimensão × área)

Em paralelo, um subagent por dimensão (áreas grandes: um por área):

- **code-reviewer** em modo sistema: aplicar o protocolo de caça dele (passadas 1-3) por módulo do escopo — em vez de diff, os arquivos do módulo; chamadores e contratos entre módulos incluídos
- **security-reviewer**: checklists do spec (auth/token, LLM se houver IA, criptografia, compliance) + pentest review da superfície real (endpoints × contratos, IDOR, SSRF, secrets)

Cada spawn recebe: escopo exato (paths), baseline da área, e o contrato de saída do próprio agente (achado = `file:line → cenário de falha → severidade`; caça documentada obrigatória).

### 3. Verificação adversarial dos achados

Todo achado **CRIT/ALTO** passa por segunda opinião antes de virar card: spawn com lente cética única — *"refute este achado: prove que o cenário de falha não acontece"*. Refutado com evidência → descartar (registrar por quê); confirmado → mantém severidade. Achados MÉDIO/BAIXO: dedup e amostragem (verificar 1 em cada 3).

### 4. Consolidar → TASK_BOARD

- Dedup entre dimensões (mesmo root cause reportado 2×)
- Cards `AUD-<n>` (ou `SEC-*`/`BUG-*`/`DEBT-*` conforme natureza) com severidade, cenário e file:line — CRIT/ALTO no topo do board
- CRIT em produção → avaliar `/squad-incident` em vez de card

### 5. Fechar o loop (obrigatório — audit sem consequência é teatro)

- Padrão repetido (3+ achados da mesma classe) → item novo no `engineer-self-review.md` + entrada no LESSONS do projeto
- Comparar com baseline: classes que voltaram = self-review/review não está segurando → pauta com o usuário
- Registrar no Session Log: `audit: N achados (C crit / A alto / M médio / B baixo), X refutados na verificação, delta vs anterior`

### 6. Relatório ao usuário

≤ 20 linhas: escopo, número por severidade, top 3 achados com cenário, delta vs baseline, recomendação de priorização. Lista completa fica nos cards.

## Anti-patterns

- Corrigir durante o audit (read-only; correção é card priorizado)
- Achado sem cenário de falha concreto (é opinião — não vira card)
- Despejar 50 achados sem dedup/priorização no board
- Pular a verificação adversarial de CRIT/ALTO (falso positivo de audit queima confiança no processo)
- Audit substituindo o review de PR (dimensões diferentes; um não dispensa o outro)

## Referências

- Protocolo de caça: `${CLAUDE_PLUGIN_ROOT}/agents/code-reviewer.md`
- Checklists de segurança: `${CLAUDE_PLUGIN_ROOT}/template/agents/security-engineer.md`
