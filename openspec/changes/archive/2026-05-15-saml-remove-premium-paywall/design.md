## Context

A lógica de paywall do frontend está centralizada em `usePolicy.js`. O composable expõe `shouldShowPaywall(featureFlag)` que:

1. Verifica se a feature está em `PREMIUM_FEATURES` (`featureFlags.js`)
2. Se estiver, avalia o tipo de instalação:
   - Cloud: retorna `!isFeatureFlagEnabled(flag)`
   - Enterprise: retorna `!hasPremiumEnterprise` (true quando `pricing_plan === 'community'`)
   - Outros: retorna `false`

`FEATURE_FLAGS.SAML` está atualmente em `PREMIUM_FEATURES`, então `shouldShowPaywall('saml')` retorna `true` em instalações Enterprise community — o que exibe `SamlPaywall.vue` e nunca chega a renderizar `SamlSettings.vue`.

O fluxo atual em `security/Index.vue`:
```
showPaywall = shouldShowPaywall('saml') → TRUE (Enterprise community)
  → <SamlPaywall v-if="showPaywall" />   ← renderiza isso

shouldShowSaml = shouldShow(...) && isSamlSsoEnabled
  → <SamlSettings v-else-if="shouldShowSaml" />  ← nunca chega aqui
```

## Goals / Non-Goals

**Goals:**
- `shouldShowPaywall('saml')` retornar `false` em qualquer tipo de instalação
- `SamlSettings.vue` renderizar para administradores com a feature habilitada e SAML em `allowedLoginMethods`
- `SamlPaywall.vue` nunca ser exibido

**Non-Goals:**
- Alterar qualquer lógica de paywall para outras features premium (SLA, Captain, etc.)
- Remover `SamlPaywall.vue` do codebase (pode ser mantido como dead code por ora)
- Modificar qualquer arquivo em `enterprise/`
- Alterar comportamento de instalações Cloud

## Decisions

### Decisão: Remover SAML de PREMIUM_FEATURES, não alterar `shouldShowPaywall`

**Escolhida:** Remover `FEATURE_FLAGS.SAML` do array `PREMIUM_FEATURES` em `featureFlags.js`.

**Alternativas consideradas:**

| Alternativa | Problema |
|---|---|
| Alterar `shouldShowPaywall` para ignorar SAML especificamente | Lógica ad-hoc, polui o composable com caso especial |
| Adicionar condição em `Index.vue` para curto-circuitar o paywall | Duplica lógica, vai contra o design do `usePolicy` |
| Mover SAML para um array separado de "enterprise-only" | Over-engineering para uma mudança de 1 linha |

**Rationale:** `PREMIUM_FEATURES` é a fonte de verdade de "o que mostra paywall". Remover SAML desse array é a mudança mais cirúrgica, semânticamente correta (SAML não é mais premium nesta instalação) e sem efeitos colaterais em outros componentes.

### Decisão: Não remover SamlPaywall.vue

O componente pode ser mantido. Sem estar no `PREMIUM_FEATURES`, o `v-if="showPaywall"` em `Index.vue` nunca será `true`, então o componente simplesmente nunca renderiza. Remoção pode ser feita em cleanup posterior.

## Risks / Trade-offs

- **[Risco] Regressão em instalações Cloud:** Se alguma conta Cloud tiver a feature `saml` desabilitada manualmente, ela deixará de ver o paywall e verá a mensagem `SAML_DISABLED_MESSAGE` em vez disso (pois `shouldShowSaml` seria `false`). → Mitigação: comportamento aceitável — sem paywall, sem formulário; a feature precisa estar habilitada na conta para mostrar o formulário, o que já era o caso antes.
- **[Risco] Outras features premium:** A mudança é escopo-limitada a `FEATURE_FLAGS.SAML` e não afeta nenhuma outra feature no array. Risco zero de regressão para SLA, Captain, etc.
- **[Trade-off] SamlPaywall.vue vira dead code:** Componente importado em `Index.vue` mas nunca renderizado. Aceitável para MVP; pode ser removido em refactor posterior.
