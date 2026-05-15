## Why

A tela de configuração SAML (`Settings > Security`) nunca é exibida em instalações self-hosted Enterprise porque o `FEATURE_FLAGS.SAML` está incluído em `PREMIUM_FEATURES`, fazendo `shouldShowPaywall('saml')` retornar `true` para qualquer conta com `pricing_plan = 'community'`. Com as Fases 1 e 2 já concluídas (feature saml habilitada por padrão e SAML sempre presente em `allowedLoginMethods`), o único bloqueio restante para o admin configurar o IdP pelo painel é este paywall de licenciamento.

## What Changes

- Remover `FEATURE_FLAGS.SAML` do array `PREMIUM_FEATURES` em `featureFlags.js`
- `shouldShowPaywall('saml')` passa a retornar `false` em qualquer tipo de instalação
- `SamlSettings.vue` é renderizado diretamente quando o usuário é administrador, a feature está habilitada na conta e SAML está em `allowedLoginMethods`
- `SamlPaywall.vue` nunca mais é exibido

## Capabilities

### New Capabilities

- `saml-settings-accessible`: A tela de configuração SAML em `Settings > Security` exibe o formulário diretamente, sem paywall, para administradores em instalações self-hosted Enterprise com a feature saml habilitada.

### Modified Capabilities

_(nenhuma — as specs existentes de `saml-feature-default` e `saml-always-in-login-methods` não têm seus requisitos alterados)_

## Impact

- **Arquivo alterado:** `app/javascript/dashboard/featureFlags.js` (1 linha removida)
- **Componentes afetados:** `Index.vue` (security settings), `SamlSettings.vue`, `SamlPaywall.vue` — sem mudança de código neles, apenas o comportamento muda
- **Sem impacto em `enterprise/`** — toda a lógica SAML no overlay Enterprise permanece intacta
- **Sem impacto de i18n** — nenhuma string nova
- **Sem impacto de API** — nenhum endpoint alterado
- **Pré-requisitos:** Fases 1 e 2 já implementadas (saml em `feature_flags` das contas e em `allowedLoginMethods`)
