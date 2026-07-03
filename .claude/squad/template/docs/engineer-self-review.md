# Engineer Self-Review — Checklist obrigatório antes de todo push

> Gate de autoavaliação de TODOS os engineers (Backend, Frontend, Mobile, AI, DevOps).
> Objetivo: reviewer e security confirmam qualidade — não descobrem problemas.
> Se um item falhar, corrigir ANTES de pushar. "Mudança pequena" (review-fix, resolução de conflito) NÃO isenta nenhum item.
>
> Origem: lições do projeto Concilia (LESSONS_LEARNED §16, §20, §21 — gates determinísticos falhavam em CI; review/security sempre achavam os mesmos problemas).

---

## §0 — Gate determinístico (100% reproduzível local; falhar em CI = falha de processo)

- [ ] Format check no repositório INTEIRO (não só arquivos tocados)
- [ ] Lint no repositório inteiro
- [ ] Typecheck completo (test runner transpila mas NÃO checa tipos — o compilador é o único portão real)
- [ ] Testes com cobertura (conforme modo MVP/Production)
- [ ] Build (incluindo `docker build` local se tocou Dockerfile/deps/build-config — build FIEL: limpar artefatos locais tipo `packages/*/dist` antes de `--no-cache`, senão o contexto sujo mascara erro de build order que só explode no provider)
- [ ] Mexeu em manifest de dependências → lockfile da RAIZ commitado junto
- [ ] Rebase em base atualizada + gate completo re-rodado, se a base mudou desde o início da tarefa

**Princípio:** CI não é onde se descobre erro de format/lint/type/build — é onde se CONFIRMA que não há. Gate determinístico vermelho em CI = o engineer não rodou o gate local.

## §1 — Segurança (self-check antes do Security Engineer)

- [ ] Nenhum PII/secret em log, métrica, mensagem de erro ou label
- [ ] Labels de métrica com cardinalidade limitada (nunca valor livre de usuário)
- [ ] Comportamento fail-closed em paths de segurança (erro não vira bypass)
- [ ] Isolamento cross-tenant: identificador do tenant no WHERE de toda escrita (defesa em profundidade, não só RLS/middleware)
- [ ] Validação/sanitização na fronteira (DTO), antes do sink (DB, log, export, UI)
- [ ] Token/credencial novo tem CONSUMER funcional + teste provando: aceita válido, rejeita revogado, rejeita expirado (comentário de intenção não é evidência)
- [ ] Env var fail-closed nova → provisionada no secret manager dos ambientes (senão crash-loop no 1º deploy real)
- [ ] Erros conhecidos preservam status (4xx não vira 500 genérico)

## §2 — Clean code / consistência

- [ ] Zero duplicação nova (código copiado entre módulos/apps = tech-debt registrado com task bloqueante)
- [ ] Doc/comentário ↔ código coerentes (comentário que descreve enforcement exige o enforcement implementado)
- [ ] Decisão registrada em comentário `// TODO` → entrada no DECISIONS_LOG no mesmo commit
- [ ] Nenhum valor mágico/hardcoded (tokens de design, limites, URLs → config)

## §3 — Testes

- [ ] TODO path/branch novo do diff tem teste de comportamento (inclusive paths de erro)
- [ ] Cobertura ≥ floor do modo; não regrediu
- [ ] Testes determinísticos (sem dependência de ordem, tempo real, estado compartilhado)
- [ ] Invariante que vive no banco (enum, constraint, RLS, trigger) → ≥1 teste de integração contra banco REAL (mock do sink esconde a classe inteira de bug)
- [ ] Fluxo multi-passo (onboarding, MFA, reset) → teste E2E com app real + DB real antes de Done

## §4 — Simplicidade (anti-over-engineering)

Responder honestamente antes de entregar:

1. **Preciso de tantas linhas?**
2. **Tem solução mais simples?**
3. **Consigo reaproveitar solução já existente com baixo esforço de adaptação?** (buscar no codebase ANTES de criar)
4. **Estou usando Clean Code?** (funções pequenas, nomes claros)
5. **Estou usando Clean Architecture?** (camadas onde agregam — não por default)
6. **Respeito o SOLID?**

Resposta "não" em 1–3 → simplificar/reaproveitar ANTES de enviar pra review. Abstração especulativa (camada/interface/config sem 2º caso de uso real) = remover (YAGNI).

---

## Loop de melhoria

Achado repetitivo de Code Reviewer ou Security Engineer → o item entra NESTE checklist (via LESSONS_LEARNED do projeto). A lista cresce até review virar confirmação. Meta: PR chegar ao review sem nenhum achado é o normal, não a exceção.
