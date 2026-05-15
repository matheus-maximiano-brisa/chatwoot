## 1. Configuração padrão de feature

- [x] 1.1 Em `config/features.yml`, alterar `enabled: false` para `enabled: true` na entry `saml` (manter `premium: true`)

## 2. Migration de dados

- [x] 2.1 Gerar nova migration: `bundle exec rails generate migration EnableSamlForAllAccounts`
- [x] 2.2 Implementar o método `up` da migration:
  - Parte A: localizar a entry `saml` em `InstallationConfig['ACCOUNT_LEVEL_FEATURE_DEFAULTS']`, setar `enabled: true`, salvar e chamar `GlobalConfig.clear_cache`
  - Parte B: iterar todas as contas via `Account.find_in_batches(batch_size: 100)` e chamar `account.enable_features!('saml')` em cada uma
- [x] 2.3 Executar a migration localmente: `bundle exec rails db:migrate`

## 3. Verificação

- [x] 3.1 Verificar em console Rails que `Account.first.feature_enabled?('saml')` retorna `true`
- [x] 3.2 Verificar que `InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').value.find { |f| f['name'] == 'saml' }` retorna `{ 'name' => 'saml', 'enabled' => true, ... }`
- [x] 3.3 Criar uma nova conta via console e verificar que `account.feature_enabled?('saml')` já nasce `true`
