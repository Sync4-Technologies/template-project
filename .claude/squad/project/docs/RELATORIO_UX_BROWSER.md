# Relatório UX Browser — AgentesIA

**Data:** 23/06/2026  
**Ambiente:** Local (`http://localhost:8080` + API `http://127.0.0.1:8000`)  
**Browser:** Chromium 145 via Playwright (headless, equivalente a Chrome)  
**Modo testado:** Claro e escuro (ambos)  
**Rede:** Desktop 1280×800 + mobile 375×812; throttling Fast 3G em `/app/agentes`  
**Evidências:** screenshots em `ia-reply/e2e-output/` (01–51)

---

## 🔴 Críticos

**FLUXO 1d / 2a — Erros de API viram "Erro inesperado"**  
Ao tentar login com credencial inválida (`naoexiste@test.local` / senha errada), o toast exibe **"Erro inesperado. Tente novamente."** em vez de *"Email ou senha incorretos."* O mesmo ocorre em `/forgot-password` com email inexistente (screenshot `04-login-erro.png`, `07-forgot-sent.png`).  
**Causa:** `getErrorMessage()` lê `response.data.detail`, mas o backend retorna `{ error: { message: "..." } }`. Afeta login, forgot-password, billing, agentes e demais fluxos com toast de erro.

**FLUXO 7a — Preços incorretos na tela de Billing**  
Na página `/app/billing`, o plano **Free** aparece com **R$ 97/mês** e botão "Plano atual". **Business** e **Enterprise** também mostram **R$ 97/mês** (placeholder duplicado). Só Starter (R$ 297) e Pro (R$ 697) parecem corretos (screenshot `30-billing.png`). Risco alto de confusão e clique errado em upgrade.

---

## 🟡 Importantes

**FLUXO 1a — Hero da landing “vazio” nos primeiros ~1s**  
No screenshot full-page da landing (`01-landing.png`), há faixa branca grande acima de "Empresas que já automatizam…". O hero usa animações `fadeUp` com `opacity: 0` inicial e delays até 0,9s — conteúdo principal (H1, CTAs) fica invisível no carregamento. Em mobile (`01-landing-mobile.png`) o texto do hero quase não contrasta com o fundo claro.

**FLUXO 1b — Cadastro: senha mínima 6 chars (prompt pedia 8)**  
Validação inline funciona (nome, empresa, termos, força de senha "Fraca/Forte"). Porém o schema exige **mínimo 6 caracteres**, enquanto `/reset-password` exige 8 — inconsistência. Email inválido dispara tooltip **nativa do browser em inglês** misturada com mensagens PT do Zod (screenshot `41-cadastro-validation.png`).

**FLUXO 1b / 1c — Pós-cadastro em dev**  
Com termos aceitos e email `@example.com`: toast **"Conta criada! Bem-vindo"** e abertura imediata do **wizard de onboarding** (4 passos), sem passar por `/login` nem tela de confirmação de email — correto para `skip_email_delivery_in_dev`, mas vale documentar para quem testa em produção com Resend.

**FLUXO 3 — Onboarding bloqueia UI**  
Após primeiro login/cadastro, modal **"Passo 1 de 4"** cobre toda a tela (`fixed inset-0 z-50`). Botões como "Novo agente" no header ficam **inacessíveis** até clicar **"Pular"** — overlay intercepta cliques. Funciona, mas frustra quem quer explorar o app antes.

**FLUXO 10c — Offline = tela em branco**  
Com internet desligada e reload em `/app/agentes`, a tela fica **completamente branca** (`39-offline.png`) — sem mensagem de rede, retry ou cache.

**FLUXO 10a — Sidebar mobile inconsistente**  
No editor mobile (`28-editor-mobile.png`): **hambúrguer + bottom nav** funcionam bem. Em `/app/agentes` no mesmo viewport, o teste não encontrou botão hambúrguer (sidebar fixa pode estar oculta/cortada dependendo do layout).

**FLUXO 2b — Reset password**  
Rota `/reset-password` existe no frontend; **não testado com token real** nesta sessão (fluxo completo depende de email/Redis). Página de forgot com email válido cadastrado não foi validada até o fim por falha no passo de notificações do script.

**FLUXO 5 — Simulador**  
Editor abre aba **"Testar"** com campos de modelo/prompt visíveis. **Simulação com mensagem real não executada** (depende de `OPENAI_API_KEY` no backend). Publicar + enviar mensagem ficou pendente.

**FLUXO 6 — Wizard Z-API**  
Empty state de conexões OK (`29-conexoes.png`) com CTA **"+ Nova conexão"** (repetido 3× na mesma página). Wizard multi-step **não aberto** nesta sessão.

**FLUXO 7a — Stripe**  
Botões "Fazer upgrade" e "Gerenciar assinatura" visíveis; **clique que abre Stripe Checkout/Portal não testado** (sem chaves Stripe de teste ativas).

**FLUXO 8 — Configurações: estrutura diferente do checklist**  
Abas reais: **Perfil, Empresa, Segurança, Notificações, API & Integrações, Zona de perigo** — não há aba "Sessões" separada; sessões ficam em **Segurança** ("Esta sessão" + texto "em breve" para múltiplas sessões). Aba API com empty state honesto (`33-config-tabs.png`).

---

## 🟢 Menores

**FLUXO 6a** — Três botões idênticos "+ Nova conexão" (header, título, empty state) na mesma viewport.

**FLUXO 4** — Banner persistente *"Você ainda não completou a configuração inicial"* mesmo após criar agente (`22-agente-criado.png`).

**FLUXO 1a** — Header da landing com "Entrar" + "Começar grátis" visíveis; sem erros de console na carga inicial.

**FLUXO 9** — Tema escuro aplica classe `dark`, persiste após reload; contraste adequado em agentes, billing e config (`43–45-*.png`). Badge "v1 · Rascunho" laranja legível no escuro.

**FLUXO 10d** — 404 customizada em `/app/rota-inexistente-xyz` com path exibido e link "Ir para a página inicial" (`38-404.png`).

**FLUXO 3b** — Dialog "Novo agente" com templates; agente aparece na listagem após criar; toast "Agente criado!".

**FLUXO 4a–f** — Abas Prompt, Tools, Multimodal, Áudio, Follow-up, Testar navegáveis; seletor OpenAI/gpt-4o; toolbar do prompt visível.

---

## ✅ Fluxos sem problemas relevantes

| Fluxo | Observação |
|-------|------------|
| **1d Login** (credenciais válidas) | Redireciona para `/app/agentes`; loading no botão perceptível |
| **1d** Link esqueci senha | Aponta para `/forgot-password` |
| **1d** Toggle senha | Ícone olho alterna visibilidade |
| **2a** Forgot-password layout | Página carrega, campo email, "Voltar ao login", layout mobile OK |
| **3a** Agentes empty state | Welcome + métricas zeradas + CTA claro |
| **3b–c** Criar/listar agente | Card com nome, status rascunho, grid responsivo |
| **4g** Salvar | Botão Salvar presente; toast sucesso ao criar |
| **4h** Editor mobile | 6 abas + bottom nav; textarea usável |
| **6a** Conexões empty | Mensagem clara, ícone smartphone |
| **7a** Billing carrega | Plano atual destacado, créditos 500, histórico vazio honesto |
| **7b** Billing mobile | Cards empilham (`31-billing-mobile.png`) |
| **8b** Perfil | Nome/email carregam (via sidebar) |
| **8c** API | Sem exposição de `tenant.id` como chave |
| **8d** Notificações | Switches `disabled` + label "Em breve" em cada item |
| **8e** Sessões | "Esta sessão" + sem sessões fake |
| **9** Tema escuro | Toggle no header; persiste em localStorage |
| **10a** Sidebar desktop | Link ativo destacado; logo AgentesIA; créditos no rodapé |
| **10b** Sessão expirada | Limpar cookies → redirect `/login` sem loop (3s) |
| **10d** 404 | Página customizada |
| **Fast 3G** | `/app/agentes` carrega em ~3s sem spinner infinito |

---

## 📱 Mobile — observações gerais

- **Landing (375px):** seções empilham bem; hero com contraste fraco; CTA final "FALAR COM AGENTE" visível; sem overflow horizontal detectado (`scrollWidth` OK).
- **Editor:** melhor experiência mobile que listagem — hambúrguer, tabs horizontais e **bottom navigation** (Agentes, Conexões, Conversas, Métricas, Billing).
- **Cadastro/login:** layout split vira coluna única; campos não testados com teclado virtual real (simulador não emula teclado iOS).
- **Billing mobile:** planos em coluna; botões acessíveis.

---

## 🌙 Tema escuro — observações

- Toggle **Alternar tema** no header → menu Claro/Escuro/Sistema funciona.
- **Persistência:** após reload continua escuro.
- Sidebar, cards de métricas, editor e billing mantêm contraste legível.
- Modais de onboarding permanecem legíveis no escuro.
- Inputs e bordas usam tokens `border`/`muted` corretamente nas telas visitadas.

---

## Priorização sugerida (antes de usuários reais)

1. **Corrigir `getErrorMessage`** para ler `error.message` (e `validation_error.field`) — desbloqueia mensagens de login, forgot-password e toda a app.
2. **Corrigir preços no Billing** (Free = R$ 0 ou sem preço; Business/Enterprise com valores reais ou "Sob consulta").
3. **Estado offline** — fallback mínimo (banner + retry) em vez de tela branca.
4. **Hero landing** — reduzir delay de animação ou `prefers-reduced-motion`; garantir H1 visível no first paint.
5. **Onboarding** — não bloquear cliques fora do modal ou abrir wizard só após primeira visita explícita.

---

## Artefatos

- Scripts de auditoria: `ia-reply/e2e/ux-audit*.spec.ts`, `ia-reply/playwright.ux.config.ts`
- Screenshots: `ia-reply/e2e-output/*.png`
- Findings JSON: `ia-reply/e2e-output/findings-part2.json`
