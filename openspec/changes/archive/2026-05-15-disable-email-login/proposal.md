## Why

Instalações self-hosted que adotam SAML SSO como método exclusivo de autenticação precisam de uma forma de desabilitar o formulário de email/senha na tela de login. Hoje não existe mecanismo para isso: o formulário de email/senha é sempre exibido, o que confunde usuários em ambientes onde o login por senha foi intencionalmente substituído pelo SSO.

## What Changes

- `DISABLE_EMAIL_LOGIN` lida via `ENV.fetch` diretamente no `DashboardController` (variável de deploy, não gerenciada via Super Admin nem armazenada no banco)
- `allowed_login_methods` no `DashboardController` passa a excluir `'email'` quando `DISABLE_EMAIL_LOGIN=true`
- Config `ENABLE_SAML_SSO_LOGIN` removida do `installation_config.yml` (tornou-se código morto após SAML ser sempre incluído em `allowed_login_methods`)
- Tela de login (`Index.vue`) passa a ocultar o formulário email/senha e o divider quando `'email'` não está em `allowedLoginMethods`

## Capabilities

### New Capabilities

- `disable-email-login`: Controla a visibilidade do formulário de email/senha na tela de login via variável de ambiente, permitindo ambientes SAML-only sem exibir formulário de senha inacessível aos usuários.

### Modified Capabilities

- `saml-always-in-login-methods`: Remoção da entrada `ENABLE_SAML_SSO_LOGIN` do `installation_config.yml`, que era a config responsável por esse gate (agora código morto).

## Impact

- **Backend**: `app/controllers/dashboard_controller.rb`, `config/installation_config.yml` (remoção de `ENABLE_SAML_SSO_LOGIN`)
- **Frontend**: `app/javascript/v3/views/login/Index.vue`
- **OSS vs Enterprise**: Mudança 100% em código OSS. Nenhum arquivo em `enterprise/` é tocado — a lógica de bloqueio de senha por `provider='saml'` no `SamlAuthenticationHelper` já existe e permanece inalterada.
- **Compatibilidade**: Com `DISABLE_EMAIL_LOGIN=false` (padrão), comportamento atual é idêntico — zero impacto em instalações que não usam SAML.
