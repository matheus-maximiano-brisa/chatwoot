# Capability: saml-feature-default

## Purpose

Garante que a feature `saml` esteja habilitada por padrão em todas as contas do Chatwoot — novas e existentes — sem necessidade de ativação manual. Esta capability é o pré-requisito para que os gates downstream de SAML SSO (configuração de IdP, login SSO, bloqueio de senha) funcionem corretamente.

## Requirements

### Requirement: Feature SAML habilitada por padrão em novas contas
O sistema SHALL criar toda nova conta com a feature `saml` habilitada no bitmap `feature_flags`, sem necessidade de ativação manual.

#### Scenario: Nova conta criada após a migration
- **WHEN** uma nova conta é criada via `AccountBuilder` ou API de plataforma
- **THEN** `account.feature_enabled?('saml')` retorna `true`

#### Scenario: `GET /api/v1/accounts/:id` reflete o estado da feature
- **WHEN** a API de conta é consultada para uma conta recém-criada
- **THEN** o campo `features.saml` no response JSON é `true`

### Requirement: Feature SAML habilitada em contas existentes após migration
O sistema SHALL habilitar a feature `saml` em todas as contas já existentes no banco quando a migration for executada.

#### Scenario: Migration executada em instalação com contas pré-existentes
- **WHEN** a migration `enable_saml_for_all_accounts` é executada
- **THEN** toda conta existente passa a ter `feature_enabled?('saml') == true`

#### Scenario: Migration idempotente
- **WHEN** a migration é executada mais de uma vez (ex.: re-run acidental)
- **THEN** nenhum erro é gerado e o estado final permanece `feature_enabled?('saml') == true`

### Requirement: `ACCOUNT_LEVEL_FEATURE_DEFAULTS` reflete `saml: enabled: true`
O sistema SHALL atualizar a entrada `saml` no `InstallationConfig['ACCOUNT_LEVEL_FEATURE_DEFAULTS']` para `enabled: true`, garantindo que novas contas criadas em instalações existentes também nasçam com a feature habilitada.

#### Scenario: Conta criada em instalação existente após migration
- **WHEN** uma nova conta é criada em uma instalação onde a migration já foi executada
- **THEN** `account.feature_enabled?('saml')` retorna `true` (via `enable_default_features` no `before_create`)
