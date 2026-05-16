## ADDED Requirements

### Requirement: Senha obrigatoria no onboarding de instalacao em qualquer modo de login
O sistema SHALL manter o campo de senha obrigatorio no onboarding de instalacao, independentemente do valor de `DISABLE_EMAIL_LOGIN`.

#### Scenario: Campo senha permanece obrigatorio com DISABLE_EMAIL_LOGIN=true
- **WHEN** `DISABLE_EMAIL_LOGIN=true` e a pagina `/installation/onboarding` e acessada
- **THEN** o campo `Password` e renderizado como obrigatorio

#### Scenario: Campo senha permanece obrigatorio com DISABLE_EMAIL_LOGIN=false
- **WHEN** `DISABLE_EMAIL_LOGIN` esta ausente ou configurado como `false`
- **THEN** o campo `Password` continua renderizado como obrigatorio

### Requirement: Nota contextual para senha em ambiente SSO-only
O sistema SHALL exibir uma nota contextual abaixo do campo `Password` no onboarding de instalacao quando `DISABLE_EMAIL_LOGIN=true`, informando que essa senha e utilizada exclusivamente para acesso ao `/super_admin`.

#### Scenario: Nota visivel quando DISABLE_EMAIL_LOGIN=true
- **WHEN** `DISABLE_EMAIL_LOGIN=true` e a pagina `/installation/onboarding` e carregada
- **THEN** a nota contextual e exibida abaixo do campo `Password`
- **AND** a mensagem explicita que o login no app principal sera via SSO e que a senha e exclusiva do `/super_admin`

#### Scenario: Nota oculta quando DISABLE_EMAIL_LOGIN=false
- **WHEN** `DISABLE_EMAIL_LOGIN` esta ausente ou configurado como `false`
- **THEN** a nota contextual nao e exibida

### Requirement: Fluxo de criacao do SuperAdmin permanece inalterado
O sistema SHALL preservar o fluxo atual de criacao do usuario `SuperAdmin` no onboarding de instalacao, usando a senha informada para autenticacao no `/super_admin`.

#### Scenario: Credenciais criadas no onboarding autenticam no super admin
- **WHEN** o onboarding de instalacao e concluido com email e senha validos
- **THEN** o usuario `SuperAdmin` e criado com a senha informada
- **AND** o acesso em `/super_admin/sign_in` com essas credenciais permanece funcional
