## 1. Backend — Configuração e allowed_login_methods

- [x] 1.1 Remover a entrada `ENABLE_SAML_SSO_LOGIN` de `config/installation_config.yml`
- [x] 1.2 Remover entrada `DISABLE_EMAIL_LOGIN` de `config/installation_config.yml` (variável de deploy lida via ENV, não armazenada no banco)
- [x] 1.3 Em `DashboardController#allowed_login_methods`, tornar a inclusão de `'email'` condicional via `ENV.fetch('DISABLE_EMAIL_LOGIN', 'false') == 'true'`

## 2. Frontend — Tela de login

- [x] 2.1 Adicionar computed `showEmailLogin` no bloco `computed:` de `Index.vue`: retorna `this.allowedLoginMethods.includes('email')`
- [x] 2.2 Envolver o `SimpleDivider` e o `<form>` de email/senha em `<template v-if="showEmailLogin">` no template de `Index.vue`

## 3. Verificação manual

- [ ] 3.1 Com `DISABLE_EMAIL_LOGIN=false` (padrão): confirmar que a tela de login exibe formulário email/senha, botão SSO e divider normalmente
- [ ] 3.2 Com `DISABLE_EMAIL_LOGIN=true`: confirmar que apenas o botão SSO é exibido (formulário e divider ausentes)
- [ ] 3.3 Confirmar que `/app/login/sso` permanece acessível diretamente em ambos os casos
