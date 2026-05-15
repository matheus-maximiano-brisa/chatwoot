## 1. Remoção do gate de licenciamento

- [x] 1.1 Em `app/controllers/dashboard_controller.rb`, no método `allowed_login_methods`, substituir a linha condicional de SAML por `methods << 'saml'` (sem condição)

## 2. Verificação

- [x] 2.1 Reiniciar o servidor Rails e verificar no console do browser que `window.chatwootConfig.allowedLoginMethods` inclui `'saml'`
- [x] 2.2 Verificar que `window.chatwootConfig.enterprisePlanName` continua presente e com o valor correto (`'community'` em self-hosted sem licença)
- [x] 2.3 Verificar que `window.chatwootConfig.allowedLoginMethods` ainda inclui `'email'` e `'google_oauth'` (comportamento inalterado)
