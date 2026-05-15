## Why

O Chatwoot possui implementação completa de SAML SSO na camada Enterprise, mas o `DashboardController` bloqueia a inclusão de `'saml'` em `allowed_login_methods` quando `pricing_plan == 'community'` — condição verdadeira em toda instalação self-hosted sem licença cloud paga. Isso impede que instalações self-hosted utilizem SAML SSO mesmo com todo o código de suporte presente e funcional. Esta é a Fase 2 do PRD-001 (SAML SSO para Instalação Self-Hosted).

## What Changes

- `app/controllers/dashboard_controller.rb` — remover a condição composta (`pricing_plan != 'community' && ENABLE_SAML_SSO_LOGIN != 'false'`) de `allowed_login_methods` e sempre incluir `'saml'` no array de métodos permitidos

## Capabilities

### New Capabilities

- `saml-always-in-login-methods`: Garantia de que `'saml'` sempre aparece em `window.chatwootConfig.allowedLoginMethods`, independente do valor de `pricing_plan` ou de qualquer variável de ambiente de licenciamento

### Modified Capabilities

*(sem mudanças em requisitos de capabilities existentes)*

## Impact

- **`app/controllers/dashboard_controller.rb`**: única mudança de código — remoção da condição de licenciamento em `allowed_login_methods`
- **`window.chatwootConfig.allowedLoginMethods`**: passa a sempre incluir `'saml'`; comportamento de `'email'` e `'google_oauth'` permanece inalterado
- **Sem impacto em `enterprise/`**: os controllers enterprise (`auth_controller.rb`, `saml_settings_controller.rb`) verificam `ENABLE_SAML_SSO_LOGIN` com default `'true'` e já funcionam corretamente sem nenhuma alteração
- **Sem impacto em rotas, modelos ou frontend**: esta fase altera apenas o que chega ao frontend via `chatwootConfig`; as telas de login e paywall são tratadas nas Fases 3 e 4 do PRD-001
- **Impacto OSS vs Enterprise**: a mudança é exclusivamente em `app/` (OSS). O código enterprise permanece intocado. A remoção do gate em OSS é segura porque os enterprise controllers já têm seus próprios guards independentes
