## Why

O Chatwoot possui implementação completa de SAML SSO na camada Enterprise, mas a feature está desabilitada por padrão em todas as contas (`enabled: false` em `config/features.yml`). Instalações self-hosted que querem usar SAML como método primário de autenticação não conseguem ativar a feature sem intervenção manual no banco ou no painel Super Admin — criando fricção desnecessária e bloqueando as fases seguintes do PRD-001.

## What Changes

- `config/features.yml`: campo `enabled` da feature `saml` alterado de `false` para `true`
- Nova migration que atualiza `InstallationConfig['ACCOUNT_LEVEL_FEATURE_DEFAULTS']` para refletir `saml: enabled: true`
- Nova migration que habilita o bit `feature_saml` em todas as contas existentes no banco

## Capabilities

### New Capabilities

- `saml-feature-default`: Garantia de que toda conta (nova ou existente) nasce com a feature `saml` habilitada no bitmap `feature_flags`, sem necessidade de ativação manual

### Modified Capabilities

*(sem mudanças em requisitos de capabilities existentes)*

## Impact

- **`config/features.yml`**: alteração de configuração padrão — impacta novas instalações (banco zerado)
- **`InstallationConfig['ACCOUNT_LEVEL_FEATURE_DEFAULTS']`**: atualizado via migration — impacta comportamento do `before_create` do model `Account` para novas contas em instalações existentes
- **`accounts.feature_flags`**: migration de dados — habilita bit `saml` em todas as contas existentes
- **Sem impacto em `enterprise/`**: nenhum arquivo enterprise é modificado; o código SAML enterprise já está correto e permanece intocado
- **Sem impacto em API pública**: a feature `saml` já aparece no response de `GET /api/v1/accounts/:id` — apenas o valor muda de `false` para `true`
- **Sem impacto em frontend**: esta fase não altera paywall nem gates de login — cobertos nas Fases 3 e 4 do PRD-001
