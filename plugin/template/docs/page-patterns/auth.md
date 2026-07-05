# Pattern — Auth (login, registro, reset, MFA)

**Propósito:** entrar/criar conta com o MÍNIMO de fricção sem comprometer segurança. Fluxo UX sensível — coordenação PD + Security Engineer obrigatória (security-engineer.md → fluxos UX sensíveis).

## Layout (todas as telas de auth)

```
[Card centrado, largura ~400px, sobre fundo neutro]
[Logo pequeno no topo]
[Título da ação + 1 linha de contexto]
[Form]
[Ação primária full-width]
[Links secundários abaixo (esqueci senha / criar conta / voltar ao login)]
```

Sem navegação do app; sem distração. Mobile: card vira tela inteira.

## Login

Email + senha (toggle mostrar/hover no ícone), "esqueci minha senha" SEMPRE visível, erro de credencial genérico ("email ou senha incorretos" — nunca revelar qual; timing constante é do backend), submit disabled durante request com loading no botão.

## Registro

Só os campos essenciais (nome/email/senha — resto vai pro onboarding); requisitos de senha visíveis ANTES do erro (checklist dinâmico); termos como checkbox com link; verificação de email como passo explícito ("enviamos um link para X" + reenviar com cooldown).

## Reset de senha

Pedido: só email; resposta SEMPRE igual exista ou não a conta ("se existir conta, enviamos o link" — sem user enumeration). Redefinição: nova senha + confirmação + mesmos requisitos visíveis; token expirado = mensagem clara + botão pedir novo (nunca 500).

## MFA (quando o produto exige)

Setup: QR code + código manual como fallback + campo de confirmação do primeiro código ANTES de ativar. Uso: campo único de 6 dígitos com auto-submit, opção de código de recuperação. Step-up (ação sensível): explicar POR QUE está pedindo de novo.

## Estados

Loading no botão (nunca tela); erro acionável acima do form; rate-limit atingido: mensagem com tempo de espera (nunca erro genérico); sessão expirada ao voltar: aviso claro + form preservando email.

## Anti-patterns

Revelar se o email existe; requisitos de senha só depois do erro; MFA ativado sem confirmar o primeiro código (lição §27 Concilia — fluxo de aceite quebrado E2E); logout sem confirmação quando há trabalho não salvo; captcha antes de qualquer tentativa.
