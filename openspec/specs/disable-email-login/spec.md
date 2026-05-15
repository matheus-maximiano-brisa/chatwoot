# Capability: disable-email-login

## Purpose

Permite que instalações self-hosted removam o formulário de email/senha da tela de login via variável de ambiente `DISABLE_EMAIL_LOGIN`. Quando ativa, apenas métodos alternativos (SAML SSO, Google OAuth) são exibidos, tornando o ambiente exclusivamente SSO para o app principal.

## Requirements

### Requirement: Email ausente de allowed_login_methods quando DISABLE_EMAIL_LOGIN=true
O sistema SHALL excluir `'email'` do array `allowed_login_methods` quando a config `DISABLE_EMAIL_LOGIN` estiver definida como `true`.

#### Scenario: Email removido com DISABLE_EMAIL_LOGIN=true
- **WHEN** `DISABLE_EMAIL_LOGIN` está configurado como `true` na instalação
- **THEN** `DashboardController#allowed_login_methods` retorna array sem `'email'`
- **AND** `window.chatwootConfig.allowedLoginMethods` não contém `'email'`

#### Scenario: Email presente com DISABLE_EMAIL_LOGIN=false (padrão)
- **WHEN** `DISABLE_EMAIL_LOGIN` está ausente ou configurado como `false`
- **THEN** `DashboardController#allowed_login_methods` retorna array contendo `'email'`
- **AND** comportamento atual é idêntico ao estado anterior a esta mudança

### Requirement: Formulário de email/senha oculto na tela de login quando email desabilitado
O sistema SHALL ocultar o formulário de email/senha e o divider na tela de login quando `'email'` não estiver presente em `allowedLoginMethods`.

#### Scenario: Formulário e divider ocultos com email desabilitado
- **WHEN** `allowedLoginMethods` não contém `'email'`
- **THEN** o formulário com campos email e senha não é renderizado
- **AND** o `SimpleDivider` entre os botões OAuth/SAML e o formulário não é renderizado

#### Scenario: Botão SSO permanece visível com email desabilitado
- **WHEN** `allowedLoginMethods` não contém `'email'`
- **AND** `allowedLoginMethods` contém `'saml'`
- **THEN** o botão "Entrar com SSO" é o único elemento de login visível

#### Scenario: Comportamento inalterado quando email habilitado
- **WHEN** `allowedLoginMethods` contém `'email'`
- **THEN** formulário de email/senha e divider são renderizados normalmente
- **AND** nenhuma alteração visual em relação ao estado anterior

### Requirement: Rota SSO acessível independente da config
O sistema SHALL manter a rota `/app/login/sso` acessível diretamente, independente do valor de `DISABLE_EMAIL_LOGIN`.

#### Scenario: Rota SSO acessível com email desabilitado
- **WHEN** `DISABLE_EMAIL_LOGIN=true`
- **THEN** a rota `/app/login/sso` responde normalmente
- **AND** o formulário de SSO (campo email) é exibido
