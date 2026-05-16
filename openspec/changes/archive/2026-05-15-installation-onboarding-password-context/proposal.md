## Why

Na configuracao SSO-only (`DISABLE_EMAIL_LOGIN=true`), o onboarding de instalacao continua exigindo senha, mas nao explica claramente para que ela sera usada. Isso pode levar operadores a interpretar que a senha nao e mais relevante e gerar bloqueio operacional no acesso ao painel `/super_admin`, que permanece dependente de email+senha.

## What Changes

- Exibir uma nota contextual no onboarding de instalacao quando `DISABLE_EMAIL_LOGIN=true`, informando que a senha e usada exclusivamente no `/super_admin`.
- Manter o campo de senha obrigatorio no onboarding de instalacao, sem alterar validacoes ou fluxo de criacao de conta.
- Preservar comportamento atual quando `DISABLE_EMAIL_LOGIN=false` (sem nota adicional).
- Nao alterar autenticacao do app principal, autenticacao do `/super_admin`, nem regras SAML existentes.

## Capabilities

### New Capabilities
- `installation-onboarding-password-context`: define o comportamento do onboarding de instalacao para manter senha obrigatoria e exibir orientacao contextual em ambiente SSO-only.

### Modified Capabilities
- `disable-email-login`: explicita que a desativacao de email no login do app principal nao remove a necessidade de senha no onboarding de instalacao para acesso ao `/super_admin`.

## Impact

- Codigo afetado:
  - `app/views/installation/onboarding/index.html.erb`
  - (opcional para cobertura) `spec/controllers/installation/onboarding_controller_spec.rb`
- APIs e contratos: sem mudancas de API.
- Banco de dados: sem mudancas.
- Dependencias: sem novas dependencias.

### Impacto OSS vs Enterprise

A mudanca ocorre no fluxo OSS de onboarding de instalacao e nao altera codigo `enterprise/`. O comportamento continua compativel com o overlay Enterprise, pois apenas esclarece UX e nao modifica regras de autenticacao SAML nem do Super Admin.
