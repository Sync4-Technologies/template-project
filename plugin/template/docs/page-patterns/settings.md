# Pattern — Settings

**Propósito:** encontrar e alterar uma configuração em <15s, com clareza do que é da CONTA vs do WORKSPACE/organização.

## Estrutura

```
[Navegação lateral de seções (desktop) / lista → drill-down (mobile)]
[Seções típicas: Perfil | Conta (email, senha, MFA) | Workspace/Organização | Membros | Billing | Integrações | Notificações | Zona de perigo]
[Área de conteúdo: 1 seção por vez, título + descrição curta + grupos de campos]
```

- Separar visualmente escopo pessoal × escopo do workspace (headers de grupo na navegação)
- Cada configuração: label + descrição de 1 linha do EFEITO ("Notificar quando X acontecer")
- Salvar por seção (botão aparece quando há mudança) OU auto-save com feedback "salvo" — um dos dois, consistente

## Zona de perigo

Seção própria, no fim, visualmente distinta (borda de alerta): deletar conta/workspace, transferir ownership. Ação destrutiva exige confirmação com digitação do nome do recurso + explicação do que se perde. Irreversível dito EXPLICITAMENTE.

## Billing (quando houver)

Plano atual + uso vs limite (barra) + próxima cobrança; upgrade como ação primária da seção; histórico de faturas como tabela com download; cancelamento acessível (não escondido) com confirmação e data de efeito.

## Estados

Loading: skeleton por seção; erro de save: inline no campo/grupo, valor do usuário preservado; permissão insuficiente: campo visível mas disabled com tooltip do porquê (não sumir a opção); mudança sensível (email, senha): confirmação por senha atual ou re-auth.

## Anti-patterns

Config escondida em sub-sub-menu; toggle que salva sem feedback; zona de perigo misturada às seções normais; membro sem permissão vendo erro 403 cru ao clicar; descrição que repete o label sem explicar o efeito.
