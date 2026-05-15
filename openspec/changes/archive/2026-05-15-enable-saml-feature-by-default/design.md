## Context

O Chatwoot usa um bitmap de feature flags (`feature_flags` na tabela `accounts`) controlado pelo concern `Featurable`. As features e seus valores padrão são definidos em `config/features.yml` e propagados para o banco via `InstallationConfig['ACCOUNT_LEVEL_FEATURE_DEFAULTS']` pelo `ConfigLoader`.

Estado atual:
- `config/features.yml`: `saml { enabled: false, premium: true }`
- `InstallationConfig['ACCOUNT_LEVEL_FEATURE_DEFAULTS']`: entry `saml` com `enabled: false`
- Contas existentes: bit `feature_saml` desligado

O `ConfigLoader` opera com `reconcile_only_new: true` por padrão — ele **não retroage** em entradas já existentes no `InstallationConfig`. Por isso, mudar apenas o `features.yml` não é suficiente: é necessária uma migration que atualize explicitamente a entry `saml` no JSON do `InstallationConfig` e também habilite o bit em contas existentes.

O campo `premium: true` no `features.yml` é apenas cosmético (usado pelo Super Admin UI para separar a exibição) e não tem efeito no runtime. Será mantido para minimizar ruído no diff.

O código SAML enterprise (`enterprise/app/models/account_saml_settings.rb`, controllers, builders, helpers) já está correto e **não será tocado**.

## Goals / Non-Goals

**Goals:**
- Toda conta nova nasce com `feature_enabled?('saml') == true`
- Toda conta existente passa a ter `feature_enabled?('saml') == true` após rodar a migration
- `GET /api/v1/accounts/:id` retorna `features: { saml: true }` para todas as contas

**Non-Goals:**
- Remover gates de `pricing_plan` ou `ENABLE_SAML_SSO_LOGIN` do backend (Fase 2 do PRD-001)
- Remover SAML de `PREMIUM_FEATURES` no frontend (Fase 3)
- Adicionar suporte a `DISABLE_EMAIL_LOGIN` (Fase 4)
- Modificar qualquer arquivo em `enterprise/`

## Decisions

**Decisão 1: Manter `premium: true` em `features.yml`**
Alternativa considerada: remover o campo. Optou-se por manter para reduzir ruído no diff — o campo é cosmético e sua remoção não agrega valor funcional.

**Decisão 2: Migration única com duas partes (A + B)**
- Parte A: atualiza a entry `saml` no JSON de `ACCOUNT_LEVEL_FEATURE_DEFAULTS` em `InstallationConfig` + invalida o cache `GlobalConfig`
- Parte B: itera contas existentes via `find_in_batches(batch_size: 100)` e chama `enable_features!('saml')`

Alternativa considerada: duas migrations separadas. Optou-se por uma única migration para manter atomicidade conceitual e seguir o padrão de migrations recentes do projeto.

**Decisão 3: Sem método `down` na migration**
Seguindo o padrão de `20260120121402_enable_captain_tasks_for_existing_accounts.rb` e `20260409091202_enable_assignment_v2_for_new_accounts.rb`. Reverter a habilitação de uma feature em produção requer decisão consciente, não rollback automático.

**Decisão 4: Guard silencioso se `ACCOUNT_LEVEL_FEATURE_DEFAULTS` não existir**
A Parte A é pulada se o config não existir no banco. A Parte B ainda roda. Quando o `ConfigLoader` executar no próximo boot, criará a entry `saml` já como `true` (graças à mudança em `features.yml`).

## Risks / Trade-offs

**[Performance em produção com muitas contas]** → `find_in_batches(batch_size: 100)` mitiga o risco de carregar todas as contas em memória. O padrão já é usado em migrations semelhantes no projeto.

**[Migration idempotente]** → `enable_features!('saml')` seta o bit independentemente do estado anterior. Rodar duas vezes não causa problema.

**[Fases subsequentes dependem desta]** → As Fases 2 e 3 do PRD-001 (remoção de gates e paywall) só fazem efeito completo após esta fase habilitar a feature. A ordem de deploy deve respeitar Fase 1 → Fase 2 → Fase 3.
