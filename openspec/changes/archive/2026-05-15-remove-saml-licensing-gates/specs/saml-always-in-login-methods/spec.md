## ADDED Requirements

### Requirement: SAML sempre presente em allowed_login_methods
O sistema SHALL incluir `'saml'` no array `allowed_login_methods` independentemente do valor de `pricing_plan` ou de qualquer variável de configuração de licenciamento.

#### Scenario: SAML presente com pricing_plan community
- **WHEN** `ChatwootHub.pricing_plan` retorna `'community'` (padrão self-hosted)
- **THEN** `DashboardController#allowed_login_methods` retorna um array contendo `'saml'`

#### Scenario: SAML presente independente do ENABLE_SAML_SSO_LOGIN
- **WHEN** `ENABLE_SAML_SSO_LOGIN` está ausente ou com qualquer valor no banco
- **THEN** `DashboardController#allowed_login_methods` retorna um array contendo `'saml'`

#### Scenario: chatwootConfig reflete SAML no frontend
- **WHEN** o frontend carrega `window.chatwootConfig`
- **THEN** `window.chatwootConfig.allowedLoginMethods` inclui `'saml'`

### Requirement: Métodos email e google_oauth permanecem inalterados
O sistema SHALL manter o comportamento atual dos demais métodos de login após a remoção do gate de SAML.

#### Scenario: email sempre presente
- **WHEN** `allowed_login_methods` é calculado
- **THEN** `'email'` está presente no array retornado

#### Scenario: google_oauth controlado por sua própria config
- **WHEN** `ENABLE_GOOGLE_OAUTH_LOGIN` está habilitado (padrão)
- **THEN** `'google_oauth'` está presente no array retornado

#### Scenario: google_oauth ausente quando desabilitado
- **WHEN** `ENABLE_GOOGLE_OAUTH_LOGIN` está setado como `'false'`
- **THEN** `'google_oauth'` não está presente no array retornado
