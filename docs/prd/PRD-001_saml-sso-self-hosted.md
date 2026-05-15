# PRD-001 — SAML SSO para Instalação Self-Hosted

## Visão Geral

O Chatwoot possui implementação completa de autenticação SAML (Security Assertion Markup Language) na camada Enterprise, porém ela está bloqueada por verificações de licenciamento (feature flags de plano pago, pricing plan, premium features). Este PRD descreve todas as mudanças necessárias para habilitar e operacionalizar o SAML SSO em uma instalação self-hosted local, substituindo o login por email/senha como método primário de autenticação para todos os usuários — exceto o usuário master criado no onboarding.

---

## Contexto e Motivação

### Arquitetura atual

O Chatwoot tem dois layers de código:

- `app/` — código OSS (open source)
- `enterprise/` — overlay que estende o OSS via `prepend_mod_with` / `include_mod_with`

A detecção de enterprise é automática: `ChatwootApp.enterprise?` retorna `true` se a pasta `enterprise/` existir. Isso significa que **todo o código SAML já está presente** no projeto — o que falta é desbloquear os gates de licenciamento.

### O que já existe (não precisa ser criado)

| Componente | Localização |
|---|---|
| Migration da tabela | `db/migrate/20250825070005_create_account_saml_settings.rb` |
| Model `AccountSamlSettings` | `enterprise/app/models/account_saml_settings.rb` |
| Controller CRUD SAML settings | `enterprise/app/controllers/api/v1/accounts/saml_settings_controller.rb` |
| OmniAuth SAML middleware | `enterprise/config/initializers/omniauth_saml.rb` |
| Builder de usuário SAML | `enterprise/app/builders/saml_user_builder.rb` |
| Callbacks controller | `enterprise/app/controllers/enterprise/devise_overrides/omniauth_callbacks_controller.rb` |
| Sessions controller (bloqueio senha) | `enterprise/app/controllers/enterprise/devise_overrides/sessions_controller.rb` |
| Helper de autenticação SAML | `enterprise/app/helpers/saml_authentication_helper.rb` |
| Tela de login SSO | `app/javascript/v3/views/login/Saml.vue` |
| Formulário de configuração SAML | `app/javascript/dashboard/routes/dashboard/settings/security/components/SamlSettings.vue` |
| Gem `omniauth-saml` | `Gemfile` |
| Feature `saml` declarada | `config/features.yml` |
| Rotas SAML | `config/routes.rb` |

### O que está bloqueando

1. Feature flag `saml` desabilitada por padrão nas contas
2. `allowed_login_methods` gateado por `pricing_plan != 'community'` e `ENABLE_SAML_SSO_LOGIN`
3. Paywall frontend: SAML em `PREMIUM_FEATURES` → exibe paywall em vez do formulário
4. Login com email/senha não tem gate por ambiente — aparece sempre
5. Onboarding coleta senha mesmo quando SAML será o único método de auth
6. Após primeiro login SAML, usuário SuperAdmin pode ter seu `provider` migrado para `saml`, o que é desejável para usuários comuns mas deve ser controlado

---

## Conceitos e Glossário

| Termo | Definição |
|---|---|
| **IdP** (Identity Provider) | Serviço que autentica o usuário. No nosso caso: Google Workspace |
| **SP** (Service Provider) | A aplicação que consome a autenticação. No nosso caso: Chatwoot |
| **SSO** (Single Sign-On) | Login único que autentica em múltiplos sistemas |
| **SAML** | Protocolo XML para troca de dados de autenticação entre IdP e SP |
| **ACS URL** (Assertion Consumer Service) | URL do SP para onde o IdP redireciona após autenticação. Formato: `{FRONTEND_URL}/omniauth/saml/callback?account_id={id}` |
| **SP Entity ID** | Identificador único do Chatwoot como SP. Formato: `{FRONTEND_URL}/saml/sp/{account_id}` |
| **IDP Entity ID** | Identificador único do Google como IdP |
| **SSO URL** | URL do Google para onde o usuário é redirecionado para autenticar |
| **Certificado X.509** | Certificado público do IdP para validar as respostas SAML |
| **`provider`** | Campo no model `User` que indica o método de auth (`nil` = email, `'saml'` = SAML) |
| **`feature_flags`** | Bitmap no model `Account` que controla features habilitadas |
| **`pricing_plan`** | Valor em `InstallationConfig['INSTALLATION_PRICING_PLAN']`, padrão `'community'` |
| **`PREMIUM_FEATURES`** | Array no frontend que determina quais features mostram paywall |

---

## Regras de Negócio

### RN-001 — SAML como método primário de autenticação
Em ambientes com `DISABLE_EMAIL_LOGIN=true`, o único método de autenticação disponível é SAML. O formulário de email/senha não deve ser exibido.

### RN-002 — Preservação do usuário master
O usuário criado no onboarding (SuperAdmin) deve manter capacidade de autenticar via SAML depois que o sistema for configurado. Seu `type = 'SuperAdmin'` e `role = 'administrator'` devem ser preservados após a migração para `provider = 'saml'`.

### RN-003 — Onboarding com senha contextual em ambiente SAML-only
Quando `DISABLE_EMAIL_LOGIN=true`, o formulário de onboarding deve manter o campo senha obrigatório. O painel Super Admin (`/super_admin`) sempre autentica via email + senha diretamente, sem SAML. A senha definida no onboarding é a única credencial de acesso ao Super Admin — ocultá-la ou substituí-la por um valor aleatório bloquearia o admin do próprio painel de administração. O campo deve ser acompanhado de nota contextual informando que esta senha serve exclusivamente para o acesso ao `/super_admin`.

### RN-004 — Migração automática de provider
No primeiro login SAML de um usuário existente (criado com email/senha), o `SamlUserBuilder` migra automaticamente `user.provider` para `'saml'`. A partir desse momento, o login com senha é bloqueado pelo `SamlAuthenticationHelper`.

### RN-005 — Novos usuários com SAML por padrão
Toda conta criada após a configuração já deve nascer com a feature `saml` habilitada. Isso é garantido por `config/features.yml` com `enabled: true` e o mecanismo `enable_default_features` no `before_create` do model `Account`.

### RN-006 — Contas existentes precisam de migração explícita
O `ConfigLoader` usa `reconcile_only_new: true` — não retroage em contas existentes. Uma migration deve habilitar a feature `saml` em todas as contas existentes.

### RN-007 — Configuração SAML por conta
O `AccountSamlSettings` é por conta (`account_id`). Cada conta tem sua própria configuração de IdP. O middleware OmniAuth lê a configuração dinamicamente por `account_id` em cada request.

### RN-008 — FRONTEND_URL deve ser acessível pelo Google
O Google Workspace precisa redirecionar para `{FRONTEND_URL}/omniauth/saml/callback`. Em produção, deve ser HTTPS com domínio público. Em desenvolvimento, usar ngrok ou equivalente.

### RN-009 — SAML sempre ativo
Não haverá gate de `pricing_plan` ou variável `ENABLE_SAML_SSO_LOGIN`. SAML é sempre incluído em `allowed_login_methods` nesta instalação.

---

## Fluxos de Usuário

### Fluxo 1 — Setup inicial do sistema

```
[1] Deploy da aplicação
        ↓
[2] Primeiro acesso → /app/onboarding
    Formulário: nome, email, organização
    (sem campo senha quando DISABLE_EMAIL_LOGIN=true)
        ↓
[3] AccountBuilder cria:
    - Account com features padrão (incluindo saml=true)
    - User com type=SuperAdmin, provider=nil
    - Senha gerada: SecureRandom.hex(32)
        ↓
[4] Redirect para /app/login
    Tela exibe apenas botão "Entrar com SSO"
    (formulário email/senha oculto por DISABLE_EMAIL_LOGIN)
        ↓
[5] Admin ainda NÃO pode logar via SAML
    (AccountSamlSettings ainda não configurado)
    → Admin deve configurar o Google SAML primeiro
```

### Fluxo 2 — Configuração do Google SAML (feita uma única vez)

```
[1] Admin acessa Google Admin Console
    → Apps → Web and mobile apps → Add custom SAML app
        ↓
[2] Google fornece:
    - SSO URL (ex: https://accounts.google.com/o/saml2/idp?idpid=XXXXX)
    - IDP Entity ID (ex: https://accounts.google.com/o/saml2?idpid=XXXXX)
    - Certificado X.509 (download)
        ↓
[3] Admin informa ao Google:
    - ACS URL: {FRONTEND_URL}/omniauth/saml/callback?account_id={id}
    - SP Entity ID: {FRONTEND_URL}/saml/sp/{id}
    - Name ID format: EMAIL
    - Attribute mapping: first_name, last_name
        ↓
[4] Admin acessa Chatwoot em modo especial (via rails console ou
    acesso direto ao DB) para configurar o AccountSamlSettings:
    - sso_url: <valor do Google>
    - idp_entity_id: <valor do Google>
    - certificate: <conteúdo do certificado PEM>
```

### Fluxo 3 — Primeiro login do admin após configuração SAML

```
[1] Admin acessa /app/login/sso
    Digita email corporativo
        ↓
[2] POST /api/v1/auth/saml_login
    Backend: encontra usuário pelo email
    Verifica: account tem saml_settings configurado? → sim
        ↓
[3] Redirect para /auth/saml?account_id=X&RelayState=web
        ↓
[4] OmniAuth middleware:
    Busca AccountSamlSettings para account_id=X
    Configura: idp_cert, sso_url, sp_entity_id, acs_url
        ↓
[5] Redirect para Google (SSO URL do IdP)
        ↓
[6] Admin autentica no Google
        ↓
[7] Google redireciona para ACS URL (callback)
    GET /omniauth/saml/callback?account_id=X
        ↓
[8] SamlUserBuilder:
    - Encontra user pelo email
    - user_belongs_to_account? → true
    - confirm_user_if_required → já confirmado
    - convert_existing_user_to_saml → provider = 'saml'
    - add_user_to_account → role preservado ('administrator')
    - type preservado (SuperAdmin)
        ↓
[9] sign_in_user → redirect para /app/login?email=...&sso_auth_token=...
        ↓
[10] Frontend: detecta sso_auth_token → login automático → dashboard
```

### Fluxo 4 — Login cotidiano de usuário comum

```
[1] Usuário acessa /app/login
    Vê apenas botão "Entrar com SSO"
        ↓
[2] Clica → /app/login/sso
    Digita email corporativo
        ↓
[3] Se usuário não existe ainda:
    SamlUserBuilder#create_user cria com provider='saml',
    senha aleatória, adiciona à conta como 'agent'
        ↓
    Se usuário existe:
    Migra provider='saml', preserva role e demais dados
        ↓
[4] Login efetuado → dashboard
```

### Fluxo 5 — Tentativa de login com senha (bloqueado)

```
[1] Usuário tenta POST /auth/sign_in com email+senha
        ↓
[2] Enterprise::DeviseOverrides::SessionsController#create
    saml_user_attempting_password_auth?(email)?
        ↓
    user.provider == 'saml'? → SIM
        ↓
[3] Retorna 401 com mensagem:
    "Please use SSO to sign in"
```

---

## Dependências e Pré-requisitos

| Dependência | Descrição |
|---|---|
| Google Workspace | Conta com acesso admin para criar SAML apps |
| `FRONTEND_URL` | Deve ser HTTPS público em produção; ngrok em dev |
| `enterprise/` presente | `ChatwootApp.enterprise?` deve retornar `true` |
| Migration executada | `account_saml_settings` table deve existir |
| `omniauth-saml` gem | Já no Gemfile, não requer mudança |

---

## Fases de Implementação

Cada fase gera um change independente e testável.

---

### Fase 1 — Habilitar feature SAML por padrão em todas as contas ✅

**Objetivo:** Toda conta (nova ou existente) nasce com `feature_enabled?('saml') == true`.

**Arquivos:**
- `config/features.yml` — mudar `saml: enabled: false → true`
- `db/migrate/YYYYMMDDHHMMSS_enable_saml_for_existing_accounts.rb` — migration que itera contas existentes e chama `enable_features!('saml')`

**Regras de negócio:** RN-005, RN-006

**Critérios de aceite:**
- `Account.new.feature_enabled?('saml')` retorna `true` após `enable_default_features`
- Contas existentes no banco têm o bit `feature_saml` setado
- `GET /api/v1/accounts/:id` retorna `features: { saml: true }`

---

### Fase 2 — Remover gates de licenciamento do SAML no backend

**Objetivo:** SAML sempre disponível em `allowed_login_methods`, sem dependência de `pricing_plan` ou `ENABLE_SAML_SSO_LOGIN`.

**Arquivos:**
- `app/controllers/dashboard_controller.rb` — simplificar `allowed_login_methods`: remover a condição inteira de SAML e sempre incluir `'saml'` no array

**Regras de negócio:** RN-009

**Critério de aceite:**
- `window.chatwootConfig.allowedLoginMethods` sempre inclui `'saml'`
- Independente do valor de `INSTALLATION_PRICING_PLAN` no banco

---

### Fase 3 — Remover paywall SAML no frontend

**Objetivo:** A tela de configuração SAML (`Settings > Security`) exibe o formulário diretamente, sem paywall.

**Arquivos:**
- `app/javascript/dashboard/featureFlags.js` — remover `FEATURE_FLAGS.SAML` do array `PREMIUM_FEATURES`

**Regras de negócio:** RN-005 (feature habilitada + sem premium gate = formulário exibido)

**Critério de aceite:**
- `shouldShowPaywall('saml')` retorna `false`
- `SamlSettings.vue` renderiza quando `account.features.saml == true`
- `SamlPaywall.vue` nunca é exibido

---

### Fase 4 — Controle de login por ambiente (`DISABLE_EMAIL_LOGIN`)

**Objetivo:** Quando `DISABLE_EMAIL_LOGIN=true`, a tela de login exibe apenas o botão SSO, ocultando o formulário email/senha.

**Arquivos:**
- `config/installation_config.yml` — adicionar entrada `DISABLE_EMAIL_LOGIN` como boolean, padrão `false`
- `app/controllers/dashboard_controller.rb` — em `allowed_login_methods`, condicionar inclusão de `'email'` com base no valor da config
- `app/javascript/v3/views/login/Index.vue` — adicionar computed `showEmailLogin` e envolver o form de email/senha em `v-if="showEmailLogin"`

**Regras de negócio:** RN-001

**Critérios de aceite:**
- Com `DISABLE_EMAIL_LOGIN=false` (padrão): comportamento atual inalterado
- Com `DISABLE_EMAIL_LOGIN=true`: `allowedLoginMethods` não contém `'email'`; formulário email+senha não renderiza; botão SSO é o único elemento de login visível
- Rota `/app/login/sso` continua acessível diretamente

---

### Fase 5 — Onboarding com senha contextual em ambiente SAML-only

**Objetivo:** Quando `DISABLE_EMAIL_LOGIN=true`, o formulário de onboarding mantém o campo senha, mas exibe uma nota contextual explicando que ela será usada exclusivamente para acesso ao painel Super Admin (`/super_admin`). O login no aplicativo principal será feito via SSO.

**Motivação da revisão:**

A senha definida no onboarding serve **dois propósitos distintos**:

| Propósito | Quando SAML está ativo |
|---|---|
| Login no app principal (`/app/login`) | Substituído pelo SAML — senha não usada |
| Login no Super Admin (`/super_admin`) | **Sempre necessário** — usa `valid_password?` diretamente, sem SAML |

O painel Super Admin (`SuperAdmin::Devise::SessionsController`) autentica sempre via email + senha, independente de qualquer configuração SAML. Se a senha fosse gerada como `SecureRandom.hex(32)` internamente e não exibida ao usuário, **o dono do sistema ficaria trancado fora do painel `/super_admin`** — um bloqueio silencioso e crítico.

**Decisão:** manter o campo senha visível em todos os ambientes. Quando `DISABLE_EMAIL_LOGIN=true`, adicionar nota contextual abaixo do campo explicando sua finalidade exclusiva.

**Arquivos:**
- `app/controllers/dashboard_controller.rb` — expor `disableEmailLogin` no `chatwootConfig` para o frontend
- Componente Vue de onboarding — exibir nota contextual abaixo do campo senha quando `disableEmailLogin === true`:
  > _"Esta senha é utilizada exclusivamente para acesso ao painel de administração do sistema (`/super_admin`). O login no aplicativo será feito via SSO."_

**Regras de negócio:** RN-003 (revisada — campo senha sempre presente)

**Critérios de aceite:**
- Com `DISABLE_EMAIL_LOGIN=true`: campo senha presente e obrigatório; nota contextual visível abaixo do campo
- Com `DISABLE_EMAIL_LOGIN=false`: comportamento do onboarding inalterado, sem nota contextual
- `AccountBuilder` continua recebendo a senha normalmente — sem mudança no backend
- Usuário criado tem `provider = nil` e senha conhecida pelo admin
- Admin consegue acessar `/super_admin` com as credenciais definidas no onboarding

---

### Fase 6 — Configuração operacional (Google Workspace + AccountSamlSettings)

**Objetivo:** Documentar e formalizar o processo de configuração do Google Workspace e o cadastro do `AccountSamlSettings`.

**Entregáveis desta fase:**
- Runbook/guia de configuração (não é código — é documentação operacional)
- Script de seed ou task rake que pré-popula o `AccountSamlSettings` para facilitar setup inicial

**Conteúdo do runbook:**
1. Criação do SAML App no Google Admin Console
2. Valores a coletar do Google (SSO URL, IDP Entity ID, certificado)
3. Valores a informar ao Google (ACS URL, SP Entity ID)
4. Como cadastrar via API (`POST /api/v1/accounts/:id/saml_settings`) ou rails console
5. Checklist de verificação pós-configuração

**Regras de negócio:** RN-007, RN-008

**Ambientes:**
- Produção: `FRONTEND_URL=https://dominio.com`
- Desenvolvimento: ngrok (`ngrok http 3000`) + atualizar `FRONTEND_URL` + reconfigurar ACS URL no Google Admin

---

## Matriz de Riscos

| Risco | Probabilidade | Impacto | Contramedida |
|---|---|---|---|
| Admin perde acesso se SAML falhar antes de configurar | Alta (setup inicial) | Crítico | Fase 4 e 5 garantem que em dev `DISABLE_EMAIL_LOGIN=false` por padrão. Em prod, configurar SAML antes de ativar a variável |
| `provider` do SuperAdmin migra para `saml` no primeiro login | Certa (por design) | Baixo — é o comportamento esperado | `type=SuperAdmin` e `role=administrator` são preservados pelo `SamlUserBuilder` |
| Certificado X.509 do Google expira | Anual | Alto | Monitorar expiração e renovar no Google Admin + atualizar `AccountSamlSettings.certificate` |
| `CheckNewVersionsJob` sobrescreve `INSTALLATION_PRICING_PLAN` | Baixa (não conecta a cloud) | Nulo (Fase 2 remove dependência do pricing_plan) | Fase 2 elimina essa dependência completamente |
| ngrok URL muda entre sessões (dev) | Alta | Médio | Usar ngrok com domínio fixo pago, ou configurar SAML só em produção |
| Usuário tenta login com senha após migração SAML | Alta (hábito) | Baixo — bloqueado com mensagem clara | Mensagem de erro já existe em `messages.login_saml_user` |

---

## Variáveis de Ambiente Relevantes

| Variável | Padrão | Descrição |
|---|---|---|
| `DISABLE_EMAIL_LOGIN` | `false` | Quando `true`, remove email/senha de `allowed_login_methods` e oculta formulário de onboarding/login |
| `FRONTEND_URL` | `http://localhost:3000` | Base URL usada para montar ACS URL e SP Entity ID. Deve ser HTTPS público em produção |
| `ENABLE_SAML_SSO_LOGIN` | — | **Removida** nesta implementação — SAML sempre ativo |

---

## Ordem de Implementação Recomendada

```
Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 5 → Fase 6

Fase 1+2+3 são independentes entre si e podem ser feitas em paralelo.
Fase 4 depende de Fase 2 (SAML deve estar em allowedLoginMethods antes de ocultar email).
Fase 5 depende de Fase 4 (mesma variável DISABLE_EMAIL_LOGIN).
Fase 6 é puramente operacional e pode acontecer em paralelo com qualquer fase.
```

---

## Notas de Implementação

- **Não modificar arquivos em `enterprise/`** — todo o código SAML lá já está correto e não precisa ser tocado. As mudanças são todas nos arquivos OSS (`app/`, `config/`, frontend)
- **Manter compatibilidade com o fluxo existente** — quando `DISABLE_EMAIL_LOGIN=false`, absolutamente nada muda para instalações que não queiram SAML
- **Specs**: As mudanças de backend podem aproveitar os specs existentes em `spec/enterprise/`. Novos specs devem cobrir os comportamentos de `DISABLE_EMAIL_LOGIN`
- **I18n**: Não há strings novas a adicionar — todos os textos de SAML já existem no `en.json`
