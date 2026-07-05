# AI Stack Convention — RAG (Retrieval-Augmented Generation)

> Consultada quando a feature exige responder com base em conhecimento próprio (docs, base de tenant, histórico).
> Decisão RAG vs alternativas: ADR-006-arquitetura-ia (Architect valida).

## RAG é a escolha certa quando…

- Corpus grande demais ou dinâmico demais pra caber no contexto (modelos atuais têm 1M de contexto — corpus pequeno e estável pode ir DIRETO no prompt com cache; RAG aqui é over-engineering)
- Dados por tenant (isolamento obrigatório no retrieval — filtro de tenant no índice, nunca só no prompt)
- Fonte precisa ser citável/auditável

Alternativas a considerar antes (mais simples primeiro): contexto direto + prompt caching → tool de busca (o modelo decide quando buscar) → RAG com pipeline próprio → fine-tuning (raro; só estilo/formato, não conhecimento).

## Pipeline

### Ingestão
- Chunking por ESTRUTURA do documento (seções/headings), não por tamanho fixo cego; overlap só quando a estrutura não dá fronteira natural
- Metadata por chunk: fonte, tenant, data, seção — obrigatória para filtro e citação
- Re-ingestão incremental (hash por documento) — nunca reprocessar o corpus inteiro por mudança pontual

### Retrieval
- Híbrido (semântico + keyword/BM25) como default; semântico puro perde termos exatos (códigos, nomes)
- Filtro de tenant/ACL **no índice** (query-time filter), antes do ranking — nunca confiar que o prompt vai ignorar chunk de outro tenant
- Top-k pequeno + rerank quando a precisão importa; medir antes de adicionar rerank (custo/latência)

### Geração
- Chunks entram com fonte identificada; instruir citação e "não sei" quando o contexto não cobre a pergunta
- Conteúdo recuperado é **input não-confiável** (prompt injection indireto — documento malicioso no corpus): instruções dentro de chunks não são comandos; ver OWASP LLM no security-engineer.md

## Avaliação de retrieval (separada da eval de geração)

Avaliar as duas camadas independentemente — geração ruim com retrieval bom se corrige no prompt; retrieval ruim não se corrige na geração:

- **Retrieval**: golden set de (pergunta → chunks relevantes esperados); métricas recall@k e MRR; rodar quando mudar chunking/embedding/índice
- **Geração**: eval padrão (`evals.md`) com contexto fixo — groundedness (resposta sustentada pelos chunks?) e citação correta

## Anti-patterns (block)

- RAG para corpus que cabe no contexto com cache (complexidade sem ganho)
- Isolamento de tenant só via prompt ("ignore documentos de outros tenants")
- Chunking por N caracteres cortando tabelas/código no meio
- Avaliar só a resposta final e nunca o retrieval
- Embeddings de PII sem a mesma classificação de dados do PRD §5
