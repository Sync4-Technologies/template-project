# Pattern — Dashboard

**Propósito:** responder em <5s "como está o negócio/sistema agora e o que precisa da minha atenção".

## Estrutura

```
[Header da página: título + período/filtro global (ex: últimos 30 dias) + ação primária se houver]
[Linha de KPIs: 3-4 cards de métrica — valor grande, label, variação vs período anterior]
[Área principal (2/3): gráfico principal da métrica que define o produto]
[Área lateral (1/3): lista "precisa de atenção" ou atividade recente]
[Seção secundária: tabela resumida com link "ver todos"]
```

## Hierarquia

1. KPIs (número domina — tipografia maior da tela)
2. Gráfico principal
3. Atividade/atenção
4. Nada compete com a linha de KPIs; sem mais de 4 KPIs (escolher, não empilhar)

## Componentes (DS)

Card de métrica (valor + delta com cor semântica), chart (Recharts/equivalente com tokens do DS), lista com avatar/ícone + timestamp relativo, tabela compacta, select de período.

## Estados

- Loading: skeleton POR CARD/bloco (não spinner global) — estrutura idêntica ao conteúdo
- Empty (produto novo, sem dados): estado de boas-vindas com a 1ª ação que gera dado ("Conecte X para ver métricas") — dashboard vazio sem direção é a pior primeira impressão
- Error por bloco: bloco falho mostra retry sem derrubar o resto da tela
- Delta sem período anterior: mostrar "—", nunca "+0%" enganoso

## Responsivo

KPIs 4→2→1 colunas; gráfico full-width; lateral desce abaixo do gráfico.

## Anti-patterns

Spinner global cobrindo a tela; >4 KPIs; gráfico decorativo sem pergunta que responde; números fake até carregar (nenhum dado fake — regra da squad).
