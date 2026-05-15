## Context

O `DashboardController#allowed_login_methods` expõe os métodos de autenticação disponíveis via `window.chatwootConfig.allowedLoginMethods`. Hoje `'email'` é sempre incluído incondicionalmente. Instalações self-hosted com SAML SSO como método exclusivo de autenticação não têm como remover o formulário de email/senha da tela de login — o que gera confusão para usuários que não possuem credenciais locais.

A tela de login (`Index.vue`) já consome `allowedLoginMethods` para controlar quais botões OAuth/SAML são exibidos — o mesmo mecanismo pode ser usado para o formulário de email/senha.

## Goals / Non-Goals

**Goals:**
- Permitir que administradores self-hosted removam o formulário de email/senha da tela de login via `DISABLE_EMAIL_LOGIN=true`
- Comportamento 100% idêntico ao atual quando `DISABLE_EMAIL_LOGIN=false` (padrão)
- Remover a config `ENABLE_SAML_SSO_LOGIN` que se tornou código morto após a Fase 2

**Non-Goals:**
- Migrar `Index.vue` para Composition API (escopo separado)
- Expor `disableEmailLogin` como chave explícita no `chatwootConfig` (a Fase 5 pode ler de `allowedLoginMethods`)
- Bloquear autenticação por senha no backend (já existe via `SamlAuthenticationHelper` em `enterprise/`)
- Qualquer mudança em arquivos `enterprise/`

## Decisions

### 1. Fonte de verdade: `allowedLoginMethods`, não uma chave separada

`'email'` é excluído de `allowed_login_methods` quando `DISABLE_EMAIL_LOGIN=true`. O frontend lê via `allowedLoginMethods.includes('email')`. Não há necessidade de uma chave `disableEmailLogin` redundante no `chatwootConfig` — o array já carrega a informação.

**Alternativa descartada:** expor `disableEmailLogin: true/false` explicitamente. Criaria duas fontes para a mesma informação derivada do mesmo config.

### 2. Backend: `ENV.fetch` direto, sem passar por `InstallationConfig`

```ruby
methods << 'email' unless ENV.fetch('DISABLE_EMAIL_LOGIN', 'false') == 'true'
```

`DISABLE_EMAIL_LOGIN` é uma variável de deploy — definida pelo operador no momento do provisionamento, não pelo admin via painel. `GlobalConfigService.load` foi descartado porque cria um registro no banco com `value: false` (default do YAML) via `ConfigLoader`, e a partir daí o ENV é silenciosamente ignorado (o banco tem precedência). `ENV.fetch` é previsível: muda a variável, reinicia o container, mudou.

**Consequência**: `DISABLE_EMAIL_LOGIN` não precisa de entrada em `installation_config.yml` e não aparece no Super Admin — comportamento correto para uma variável de infraestrutura.

**Alternativa descartada:** `GlobalConfigService.load` — confirmado em teste que ignora o ENV quando já existe registro no banco criado pelo `ConfigLoader`.

### 3. Frontend: wrapping semântico `<template v-if="showEmailLogin">`

O `SimpleDivider` e o `<form>` de email/senha são semanticamente um par — o divider só faz sentido se o form existe. Envolvê-los em um `<template v-if="showEmailLogin">` é mais legível do que duas condições separadas e torna o diff auto-explicativo.

**Alternativa descartada:** atualizar só a condição do divider para `v-if="(showGoogleOAuth || showSamlLogin) && showEmailLogin"`. Menos coeso — mantém os dois elementos com lógica independente quando na prática são inseparáveis.

### 4. Remoção de `ENABLE_SAML_SSO_LOGIN`

A config foi tornada código morto pela Fase 2 (SAML sempre presente em `allowed_login_methods`). Aproveitamos a edição do `installation_config.yml` para removê-la seguindo o guideline "remove dead/unreachable/unused code".

## Risks / Trade-offs

- **[Risco] Admin ativa `DISABLE_EMAIL_LOGIN=true` antes de configurar SAML** → fica sem acesso ao app principal. Mitigação: documentar na Fase 6 que `DISABLE_EMAIL_LOGIN` deve ser ativado apenas após SAML funcional. O painel `/super_admin` permanece acessível via email/senha independentemente desta config.
- **[Trade-off] `allowedLoginMethods` como proxy de `disableEmailLogin`** → se no futuro `'email'` for removido por outro motivo, a Fase 5 (onboarding) receberia o comportamento silenciosamente. Aceitável — o cenário é improvável e o acoplamento é explícito.
