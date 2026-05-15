## MODIFIED Requirements

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
