---
name: squad-deploy-preflight
description: Conduz DevOps Engineer em pre-flight checklist antes de deploy em PaaS (Railway, Render, Fly.io etc.) — valida Docker build fiel, env vars vs schema de config, migrations e build order localmente, ANTES do push. Use antes do primeiro deploy de um serviço e sempre que mudar Dockerfile, deps, build-config ou env vars.
---

# Skill — Squad Deploy Pre-flight (PaaS)

> **Owner:** DevOps Engineer | **Revisão:** 90 dias | **Obsolescência:** provider PaaS mudar de modelo de build
>
> Origem: LESSONS_LEARNED Concilia §13/§25/§27 — provisionar 5 serviços custou ~15 commits fix-then-test (~10 min/iteração remota vs 1-2 min local). Cada item abaixo corresponde a um erro real que só apareceu depois do deploy.

---

## Quando usar

- Antes do PRIMEIRO deploy de um serviço novo em PaaS
- Antes de push que toque: Dockerfile, deps/lockfile, build-config, env vars, migrations
- Depois de adicionar pacote interno novo em monorepo

## Quando NÃO usar

- Deploy de rotina sem mudança de build/config (CI + verificação pós-merge cobrem)

---

## Sua tarefa como Claude (atuando como DevOps Engineer)

### 1. Docker build local FIEL ao provider

O provider builda a partir do **snapshot git** (sem artefatos locais). Build local só é fiel se o contexto for igualmente limpo:

```bash
# limpar artefatos que mascaram erro de build order (dist/ local "emprestado" pro COPY)
rm -rf packages/*/dist  # ou equivalente da stack
docker build --no-cache -f <Dockerfile> .
```

Checar no Dockerfile:

- [ ] Monorepo: pacotes internos buildados por **GLOB** (`--filter "./packages/*"`), nunca lista explícita — pacote novo fora da lista = build quebra só no provider
- [ ] `.dockerignore` na **RAIZ do contexto** (não em subdiretório — ali não é lido) excluindo `**/dist` + `**/node_modules`, preservando assets de runtime
- [ ] Sem features BuildKit não suportadas pelo provider (ex: cache mounts com id)
- [ ] `NODE_ENV`/equivalente NÃO setado como production no stage de build (pula devDeps → build quebra); só no stage final
- [ ] Init process (ex: `tini`) como entrypoint se o app não propaga sinais (worker que ignora SIGTERM não drena fila)
- [ ] Deps de runtime do stage final presentes (ex: openssl para clients de DB)
- [ ] Assets não-compilados (`.md`, `.json`, fixtures) copiados pro output de build

### 2. Contexto × rootDirectory do provider

- [ ] Config do provider (ex: `railway.toml`) sem `context` conflitando com rootDirectory — mismatch quebra `COPY` de paths fora do root
- [ ] watchPatterns cobrem TODOS os paths que exigem redeploy (mudança só de Dockerfile costuma NÃO disparar — gotcha recorrente)

### 3. Env vars vs schema de config

Diff entre o que o código EXIGE e o que o provider TEM:

- [ ] Extrair vars obrigatórias do schema de validação de config (Zod/pydantic/etc.), por ambiente
- [ ] Comparar com `railway variables list` / equivalente
- [ ] Secrets novos da release provisionados (config fail-closed sem secret = crash-loop)
- [ ] Semântica do env name correta (ver matriz NODE_ENV em stack-conventions — `development` em prod-bundle quebra por devDeps ausentes)
- [ ] Vars de build-time do frontend (ex: `NEXT_PUBLIC_*`) passadas como **buildArg** — var de runtime não entra em bundle já buildado

### 4. Migrations

- [ ] `migrate status` contra a DB do ambiente-alvo — aplicar pendentes ou garantir release command que roda `migrate deploy`
- [ ] Migration backward-compatible (Production Mode — ver backend-engineer.md → Migrations)

### 5. Gate final

- [ ] Os 3 itens acima verdes ANTES do push
- [ ] Pós-deploy: verificação ativa (SHA + health + smoke E2E) conforme devops-engineer.md → "Merged ≠ Deployed"

---

## Anti-patterns (rejeitar)

- Debugar build no provider por tentativa-e-erro (fix-then-push-then-wait) quando `docker build` local reproduziria
- Confiar em `docker build` local com `dist/` sujo no contexto (falso-verde clássico)
- Adicionar pacote interno sem verificar que o Dockerfile o cobre
- Setar env var de build-time como var de runtime e esperar efeito

---

## Referências

- DevOps spec: `${CLAUDE_PLUGIN_ROOT}/template/agents/devops-engineer.md` → "Verificação Ativa de Deploy" e "Padrões PaaS + Docker"
- Self-review: `${CLAUDE_PLUGIN_ROOT}/template/docs/engineer-self-review.md` → §0 (gate docker fiel)
- Stack gotchas: `${CLAUDE_PLUGIN_ROOT}/template/docs/stack-conventions/backend/nodejs.md` → "Deployment & runtime gotchas"
