## Context

O fluxo de onboarding de instalacao do Chatwoot e server-rendered em `app/views/installation/onboarding/index.html.erb` e define a senha inicial do usuario `SuperAdmin` via `Installation::OnboardingController` + `AccountBuilder`. Em paralelo, a Fase 4 ja permite ambiente SSO-only no app principal ao remover `'email'` de `allowed_login_methods` quando `DISABLE_EMAIL_LOGIN=true`.

Essa combinacao cria risco de interpretacao: operadores podem entender que senha nao e mais necessaria em ambiente SSO-only, embora o painel `/super_admin` continue autenticando exclusivamente por email+senha (`SuperAdmin::Devise::SessionsController` com `valid_password?`).

## Goals / Non-Goals

**Goals:**
- Exibir mensagem contextual no onboarding de instalacao quando `DISABLE_EMAIL_LOGIN=true`.
- Reforcar que a senha do onboarding continua necessaria para acesso ao `/super_admin`.
- Manter comportamento atual sem alteracoes quando `DISABLE_EMAIL_LOGIN=false`.

**Non-Goals:**
- Migrar onboarding de instalacao para Vue ou `chatwootConfig`.
- Alterar regras de autenticacao SAML.
- Alterar fluxo de autenticacao do `/super_admin`.
- Introduzir novas variaveis de ambiente, dependencias ou mudancas de banco.

## Decisions

### 1) Fonte de verdade da condicao: `ENV` direto no ERB

**Decisao:** avaliar `DISABLE_EMAIL_LOGIN` com `ENV.fetch('DISABLE_EMAIL_LOGIN', 'false') == 'true'` diretamente no template ERB do onboarding de instalacao.

**Racional:** o fluxo e server-rendered, e a flag representa configuracao de infraestrutura/deploy. Essa abordagem minimiza escopo e evita duplicar estado.

**Alternativa considerada:** expor `disableEmailLogin` em `window.chatwootConfig` e consumir no frontend. Foi descartada por nao trazer ganho para o fluxo atual (nao SPA) e ampliar superficie de mudanca sem necessidade.

### 2) Local da mudanca: somente onboarding de instalacao

**Decisao:** aplicar alteracao exclusivamente em `app/views/installation/onboarding/index.html.erb`, abaixo do campo `Password`.

**Racional:** e o ponto onde a senha e capturada e onde a orientacao precisa aparecer. Evita tocar fluxos nao relacionados.

**Alternativa considerada:** alterar componentes de onboarding do dashboard (`app/javascript/dashboard/routes/dashboard/onboarding/*`). Foi descartada por tratar de onboarding de conta apos login, nao do setup inicial de instalacao.

### 3) Contrato funcional preservado

**Decisao:** manter o campo de senha obrigatorio em todos os cenarios; a nota aparece apenas com `DISABLE_EMAIL_LOGIN=true`.

**Racional:** preserva RN-003 e evita risco de lockout do operador no `/super_admin`.

## Risks / Trade-offs

- **[Risco] Mensagem em pt-BR em tela atualmente em ingles** -> **Mitigacao:** seguir decisao de produto desta conversa para Fase 5; se necessario, normalizar i18n em mudanca futura dedicada.
- **[Trade-off] Uso de condicional de ambiente no template ERB** -> **Mitigacao:** manter logica simples, explicita e limitada a um trecho de UX, sem ramificacao de regra de negocio.
- **[Risco] Leitura equivocada de que o app principal aceita senha em SSO-only** -> **Mitigacao:** texto da nota deve explicitar "exclusivamente para `/super_admin`".

## Migration Plan

1. Aplicar condicional no template do onboarding para renderizar a nota apenas em `DISABLE_EMAIL_LOGIN=true`.
2. Validar manualmente os dois cenarios (`true` e `false`) no onboarding de instalacao.
3. Validar login no `/super_admin` com credenciais definidas no onboarding.
4. Rollback, se necessario: remover trecho da nota no template (sem impacto em dados persistidos).

## Open Questions

- Nenhuma pendencia tecnica bloqueante para implementacao MVP.
