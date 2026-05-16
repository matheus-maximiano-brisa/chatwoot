## MODIFIED Requirements

### Requirement: Email ausente de allowed_login_methods quando DISABLE_EMAIL_LOGIN=true
O sistema SHALL excluir `'email'` do array `allowed_login_methods` quando a config `DISABLE_EMAIL_LOGIN` estiver definida como `true`, limitando essa desativacao ao login do app principal e preservando o onboarding de instalacao e o acesso ao `/super_admin`.

#### Scenario: Email removido com DISABLE_EMAIL_LOGIN=true
- **WHEN** `DISABLE_EMAIL_LOGIN` esta configurado como `true` na instalacao
- **THEN** `DashboardController#allowed_login_methods` retorna array sem `'email'`
- **AND** `window.chatwootConfig.allowedLoginMethods` nao contem `'email'`

#### Scenario: Email presente com DISABLE_EMAIL_LOGIN=false (padrao)
- **WHEN** `DISABLE_EMAIL_LOGIN` esta ausente ou configurado como `false`
- **THEN** `DashboardController#allowed_login_methods` retorna array contendo `'email'`
- **AND** comportamento atual e identico ao estado anterior a esta mudanca

#### Scenario: Desativacao de email no app principal nao remove senha do onboarding
- **WHEN** `DISABLE_EMAIL_LOGIN=true`
- **THEN** o onboarding de instalacao em `/installation/onboarding` continua exibindo campo `Password` obrigatorio
- **AND** o acesso ao `/super_admin` permanece baseado em email+senha
