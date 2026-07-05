# Pattern — Onboarding (primeiro uso)

**Propósito:** levar o usuário novo ao PRIMEIRO VALOR do produto no menor caminho possível (RNF de usabilidade do PRD: completável por leigo, ≤N passos). Fluxo crítico — teste E2E real obrigatório (lição §27 Concilia: onboarding nunca clicado = 7 bugs em cascata).

## Estrutura

```
[Indicador de progresso: passos nomeados (ex: 1 Perfil → 2 Workspace → 3 Conectar → 4 Pronto)]
[1 decisão por passo — título orientado a benefício ("Conecte seu WhatsApp") + campo(s) + ilustração/preview opcional]
[Footer: Voltar (quando aplicável) + Continuar (primário) + "Pular por enquanto" quando o passo for opcional]
```

## Regras

- **3-5 passos no máximo**; cada passo = 1 decisão. Mais que isso → mover pro produto (progressive disclosure)
- Só é passo do onboarding o que é NECESSÁRIO pro primeiro valor; resto é opcional/pulável e reaparece como checklist no produto
- Progresso persistido: fechar e voltar retoma do mesmo passo (nunca recomeça)
- Passo de integração externa (conectar conta, API key): validar a conexão NO PASSO (teste real com feedback), não descobrir que falhou depois
- Último passo: celebração curta + CTA direto para a primeira ação real do produto (nunca dashboard vazio — ver `dashboard.md` empty state)

## Checklist pós-onboarding (opcional, recomendado)

Card dismissível no dashboard com os passos pulados ("Complete seu setup: 2 de 4") — recupera o que foi pulado sem bloquear o primeiro uso.

## Estados

Validação por passo antes de avançar (erro inline, dados preservados); passo de integração com estados conectando/sucesso/falha + retry + link de ajuda; convite de time com envio em background (não bloquear o fluxo esperando aceite).

## Anti-patterns

Pedir no onboarding o que não é necessário pro primeiro valor (cada campo custa conversão); tour de features em vez de fazer JUNTO a primeira ação; wizard que recomeça se recarregar; "Pular" que esconde o passo pra sempre; terminar num dashboard vazio sem direção.
