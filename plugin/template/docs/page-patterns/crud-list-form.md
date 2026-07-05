# Pattern — CRUD (lista + formulário)

**Propósito:** encontrar um registro em <10s e criar/editar sem medo de perder dados.

## Lista

```
[Header: título + contagem total + botão "Novo X" (ação primária)]
[Toolbar: busca (debounced) + filtros relevantes (máx 3 visíveis; resto em "Filtros") + ordenação]
[Tabela: colunas essenciais (máx 5-6) | ações por linha em menu "..." | status como badge semântico]
[Paginação OU infinite scroll — um dos dois, consistente no produto]
```

- Busca e filtros refletidos na URL (compartilhável, sobrevive a refresh)
- Linha inteira clicável → detalhe/edição; ações destrutivas só no menu, com confirmação
- Bulk actions só se o PRD pedir (YAGNI)

## Formulário (criar/editar)

```
[Título contextual: "Novo X" / "Editar {nome}"]
[Campos agrupados por afinidade; obrigatórios primeiro; 1 coluna (2 só em pares curtos tipo cidade/UF)]
[Footer fixo: Cancelar (secundário) + Salvar (primário, disabled enquanto inválido ou sem mudança)]
```

- Validação inline no blur + resumo de erros no submit; mensagem diz COMO corrigir
- Form em página própria para entidades complexas; modal/drawer só para ≤5 campos
- Dirty state: sair com mudanças não salvas pede confirmação

## Estados

- Lista loading: skeleton de linhas (mesma altura das reais)
- Lista empty SEM filtro: mensagem + botão "Criar o primeiro X"
- Lista empty COM filtro: "Nenhum resultado para {filtro}" + limpar filtros (estados diferentes!)
- Erro de submit: erro no topo do form + campos marcados; dados do usuário PRESERVADOS
- Sucesso: toast + volta pra lista com o item visível (ou permanece editando, conforme fluxo)

## Anti-patterns

Tabela com 10 colunas; delete sem confirmação; form que perde dados no erro; empty state igual para "sem dados" e "filtro sem resultado"; modal para form longo.
