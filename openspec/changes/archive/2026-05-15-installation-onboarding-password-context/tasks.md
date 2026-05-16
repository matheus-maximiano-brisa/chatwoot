## 1. Ajuste de interface no onboarding de instalacao

- [x] 1.1 Adicionar condicional no `app/views/installation/onboarding/index.html.erb` para detectar `DISABLE_EMAIL_LOGIN=true`.
- [x] 1.2 Exibir a nota contextual em pt-BR logo abaixo do campo `Password` apenas quando a condicional estiver ativa.
- [x] 1.3 Garantir que o campo `Password` continue obrigatorio e sem alteracao de validacao em qualquer valor da flag.

## 2. Preservacao de comportamento e compatibilidade

- [x] 2.1 Validar que nao houve alteracao no fluxo de criacao do `SuperAdmin` em `Installation::OnboardingController` e `AccountBuilder`.
- [x] 2.2 Confirmar que o acesso ao `/super_admin` permanece por email+senha e sem dependencia de SAML.
- [x] 2.3 Confirmar que nao ha mudancas necessarias em `enterprise/` para manter compatibilidade.

## 3. Validacao funcional da fase

- [x] 3.1 Executar validacao manual com `DISABLE_EMAIL_LOGIN=true`: nota visivel, onboarding concluido e login no `/super_admin` funcional.
- [x] 3.2 Executar validacao manual com `DISABLE_EMAIL_LOGIN=false`: nota ausente e comportamento atual preservado.
- [x] 3.3 Registrar evidencias de validacao no PR (descricao dos cenarios e resultado observado).

## Evidencias para PR

- `docker compose run --rm rails bundle exec rspec spec/controllers/installation/onboarding_controller_spec.rb:23`
  - Resultado: `1 example, 0 failures`
  - Cobre: exibicao da nota contextual quando `DISABLE_EMAIL_LOGIN=true`.
- `docker compose run --rm rails bundle exec rspec spec/controllers/installation/onboarding_controller_spec.rb:35`
  - Resultado: `1 example, 0 failures`
  - Cobre: ausencia da nota contextual quando `DISABLE_EMAIL_LOGIN=false`.
- Decisao validada em revisao/exploracao: manter texto da nota em pt-BR nesta fase (risco de idioma tratado como LOW e aceito).
