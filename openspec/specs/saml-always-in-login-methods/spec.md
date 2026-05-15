# Capability: saml-always-in-login-methods

## Purpose

Garante que `'saml'` esteja sempre presente em `DashboardController#allowed_login_methods` — e portanto em `window.chatwootConfig.allowedLoginMethods` — independentemente de `pricing_plan` ou de qualquer variável de configuração de licenciamento. Esta capability é pré-requisito para que o frontend exiba o botão SSO em instalações self-hosted.

## Requirements

### Requirement: SAML sempre presente em allowed_login_methods
O sistema SHALL incluir `'saml'` no array `allowed_login_methods` independentemente de qualquer variável de configuração de licenciamento ou ambiente.

#### Scenario: SAML presente com pricing_plan community
- **WHEN** `ChatwootHub.pricing_plan` retorna `'community'` (padrão self-hosted)
- **THEN** `DashboardController#allowed_login_methods` retorna um array contendo `'saml'`

#### Scenario: SAML sempre presente, sem dependência de configuração
- **WHEN** `allowed_login_methods` é calculado em qualquer instalação
- **THEN** `DashboardController#allowed_login_methods` retorna um array contendo `'saml'`
- **AND** nenhuma variável de ambiente ou config de banco pode remover `'saml'` do array

#### Scenario: chatwootConfig reflete SAML no frontend
- **WHEN** o frontend carrega `window.chatwootConfig`
- **THEN** `window.chatwootConfig.allowedLoginMethods` inclui `'saml'`

### Requirement: Métodos email e google_oauth permanecem inalterados
O sistema SHALL manter o comportamento atual dos demais métodos de login após a remoção do gate de SAML.

#### Scenario: email presente por padrão
- **WHEN** `allowed_login_methods` é calculado e `DISABLE_EMAIL_LOGIN` está ausente ou `false`
- **THEN** `'email'` está presente no array retornado

#### Scenario: google_oauth controlado por sua própria config
- **WHEN** `ENABLE_GOOGLE_OAUTH_LOGIN` está habilitado (padrão)
- **THEN** `'google_oauth'` está presente no array retornado

#### Scenario: google_oauth ausente quando desabilitado
- **WHEN** `ENABLE_GOOGLE_OAUTH_LOGIN` está setado como `'false'`
- **THEN** `'google_oauth'` não está presente no array retornado
