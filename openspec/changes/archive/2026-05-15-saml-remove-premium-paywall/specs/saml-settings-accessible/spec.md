# Capability: saml-settings-accessible

## Purpose

Garante que o formulário de configuração SAML (`Settings > Security`) seja exibido diretamente para administradores em instalações self-hosted Enterprise, sem exibir paywall de licenciamento. Esta capability depende de `saml-feature-default` (feature habilitada na conta) e `saml-always-in-login-methods` (SAML em `allowedLoginMethods`).

## Requirements

## ADDED Requirements

### Requirement: Formulário SAML acessível sem paywall
O sistema SHALL exibir o formulário de configuração SAML diretamente, sem paywall, quando o usuário for administrador, a feature `saml` estiver habilitada na conta e `allowedLoginMethods` incluir `'saml'`.

#### Scenario: Formulário visível em instalação Enterprise community
- **WHEN** a instalação é Enterprise com `pricing_plan = 'community'`
- **AND** a conta tem a feature `saml` habilitada
- **AND** `allowedLoginMethods` inclui `'saml'`
- **AND** o usuário autenticado tem role `administrator`
- **THEN** `SamlSettings` é renderizado em `Settings > Security`
- **AND** `SamlPaywall` não é renderizado

#### Scenario: Paywall nunca exibido para SAML
- **WHEN** `shouldShowPaywall('saml')` é avaliado em qualquer tipo de instalação
- **THEN** o resultado é `false`

#### Scenario: Formulário não exibido sem permissão de administrador
- **WHEN** o usuário autenticado tem role `agent`
- **THEN** `SamlSettings` não é renderizado em `Settings > Security`

#### Scenario: Formulário não exibido quando feature desabilitada na conta
- **WHEN** a conta não tem a feature `saml` habilitada no bitmap `feature_flags`
- **THEN** `SamlSettings` não é renderizado
- **AND** a mensagem `SAML_DISABLED_MESSAGE` é exibida no lugar

#### Scenario: Outras features premium não são afetadas
- **WHEN** `shouldShowPaywall` é avaliado para features como `sla`, `audit_logs` ou `custom_roles`
- **THEN** o comportamento permanece idêntico ao estado anterior a esta mudança
