## Context

O `DashboardController` expõe `chatwootConfig` para o frontend, incluindo `ALLOWED_LOGIN_METHODS`. O método `allowed_login_methods` monta esse array condicionalmente:

```ruby
def allowed_login_methods
  methods = ['email']
  methods << 'google_oauth' if GlobalConfigService.load('ENABLE_GOOGLE_OAUTH_LOGIN', 'true').to_s != 'false'
  methods << 'saml' if ChatwootHub.pricing_plan != 'community' && GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s != 'false'
  methods
end
```

`ChatwootHub.pricing_plan` retorna `'community'` em qualquer self-hosted sem licença cloud (`INSTALLATION_PRICING_PLAN` ausente ou com valor `'community'`). A condição `pricing_plan != 'community'` é sempre `false`, tornando SAML inacessível via frontend mesmo com toda a implementação enterprise presente e funcional.

## Goals / Non-Goals

**Goals:**
- `'saml'` sempre presente em `allowed_login_methods`, sem dependência de `pricing_plan` ou `ENABLE_SAML_SSO_LOGIN`
- Manter o comportamento de `'email'` e `'google_oauth'` intocado

**Non-Goals:**
- Modificar qualquer arquivo em `enterprise/`
- Remover o `ENABLE_SAML_SSO_LOGIN` do `installation_config.yml` — ele ainda é usado pelos enterprise controllers
- Alterar a tela de login ou o paywall SAML no frontend (Fases 3 e 4 do PRD-001)
- Alterar rotas, models ou policies

## Decisions

**Decisão 1: Remover a condição inteira — `methods << 'saml'` sem guard**

Alternativa considerada: manter o gate do `ENABLE_SAML_SSO_LOGIN` e remover apenas o gate do `pricing_plan`. Descartada porque o PRD-001 (RN-009) define "SAML sempre ativo" nesta instalação, e manter um gate parcial criaria inconsistência: o frontend seria bloqueado por uma config que os controllers enterprise ignoram como gate primário.

**Decisão 2: Manter `INSTALLATION_PRICING_PLAN` no `GLOBAL_CONFIG_KEYS`**

`INSTALLATION_PRICING_PLAN` permanece no array. `app/views/layouts/vueapp.html.erb:51` o lê de `@global_config` para popular `enterprisePlanName` no `window.chatwootConfig`, que é consumido por `usePolicy.js` e `captain/Index.vue` para controle de paywall e acesso a features premium. Removê-lo quebraria silenciosamente esse mecanismo. A remoção do paywall específico do SAML é feita na Fase 3 via `PREMIUM_FEATURES` em `featureFlags.js`.

**Decisão 3: Não tocar `enterprise/`**

Os enterprise controllers (`api/v1/auth_controller.rb` e `api/v1/accounts/saml_settings_controller.rb`) verificam `ENABLE_SAML_SSO_LOGIN` com default `'true'` e já funcionam corretamente. Não há razão para alterá-los.

## Risks / Trade-offs

**[Operador deseja desabilitar SAML via Super Admin]** → Após esta mudança, setar `ENABLE_SAML_SSO_LOGIN=false` no Super Admin não remove mais `'saml'` de `allowedLoginMethods` no frontend. Os enterprise controllers ainda o respeitam para bloquear o fluxo de login. Risco aceito: o PRD-001 define SAML como método primário desta instalação; desabilitá-lo está fora do escopo. Coberto pelo runbook da Fase 6.
