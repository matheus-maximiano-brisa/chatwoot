# Capability: installation-onboarding-password-context

## Purpose

Garante que o onboarding de instalação mantenha a senha como credencial obrigatória e explique seu uso em ambientes SSO-only, evitando perda de acesso ao `/super_admin`.

## Requirements

### Requirement: Senha obrigatória no onboarding de instalação em qualquer modo de login
O sistema SHALL manter o campo de senha obrigatório no onboarding de instalação, independentemente do valor de `DISABLE_EMAIL_LOGIN`.

#### Scenario: Campo senha permanece obrigatório com DISABLE_EMAIL_LOGIN=true
- **WHEN** `DISABLE_EMAIL_LOGIN=true` e a página `/installation/onboarding` é acessada
- **THEN** o campo `Password` é renderizado como obrigatório

#### Scenario: Campo senha permanece obrigatório com DISABLE_EMAIL_LOGIN=false
- **WHEN** `DISABLE_EMAIL_LOGIN` está ausente ou configurado como `false`
- **THEN** o campo `Password` continua renderizado como obrigatório

### Requirement: Nota contextual para senha em ambiente SSO-only
O sistema SHALL exibir uma nota contextual abaixo do campo `Password` no onboarding de instalação quando `DISABLE_EMAIL_LOGIN=true`, informando que essa senha é utilizada exclusivamente para acesso ao `/super_admin`.

#### Scenario: Nota visível quando DISABLE_EMAIL_LOGIN=true
- **WHEN** `DISABLE_EMAIL_LOGIN=true` e a página `/installation/onboarding` é carregada
- **THEN** a nota contextual é exibida abaixo do campo `Password`
- **AND** a mensagem explicita que o login no app principal será via SSO e que a senha é exclusiva do `/super_admin`

#### Scenario: Nota oculta quando DISABLE_EMAIL_LOGIN=false
- **WHEN** `DISABLE_EMAIL_LOGIN` está ausente ou configurado como `false`
- **THEN** a nota contextual não é exibida

### Requirement: Fluxo de criação do SuperAdmin permanece inalterado
O sistema SHALL preservar o fluxo atual de criação do usuário `SuperAdmin` no onboarding de instalação, usando a senha informada para autenticação no `/super_admin`.

#### Scenario: Credenciais criadas no onboarding autenticam no super admin
- **WHEN** o onboarding de instalação é concluído com email e senha válidos
- **THEN** o usuário `SuperAdmin` é criado com a senha informada
- **AND** o acesso em `/super_admin/sign_in` com essas credenciais permanece funcional
