## 1. Remover SAML de PREMIUM_FEATURES

- [x] 1.1 Em `app/javascript/dashboard/featureFlags.js`, remover a linha `FEATURE_FLAGS.SAML,` do array `PREMIUM_FEATURES`
- [x] 1.2 Verificar que nenhum outro arquivo importa `PREMIUM_FEATURES` com dependência de SAML estar nele (buscar por `PREMIUM_FEATURES` no codebase)

## 2. Verificação funcional

- [x] 2.1 Acessar `Settings > Security` como administrador e confirmar que o formulário SAML é exibido (sem paywall)
- [x] 2.2 Confirmar que `SamlPaywall` não é renderizado inspecionando o DOM ou adicionando log temporário
- [x] 2.3 Confirmar que outras features premium (ex.: SLA em `Settings > SLA`) continuam exibindo paywall normalmente em instalação community

## 3. Testes automatizados

- [x] 3.1 Rodar `pnpm test` e verificar que nenhum teste existente quebra com a remoção
- [x] 3.2 Rodar `pnpm eslint` para confirmar que não há erros de lint introduzidos
