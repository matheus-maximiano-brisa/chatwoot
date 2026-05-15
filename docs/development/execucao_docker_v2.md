# Executando o Chatwoot com Docker (v2)

Guia completo para rodar o projeto localmente usando Docker, sem necessidade de instalar Ruby ou dependências do sistema. Inclui problemas encontrados na prática e suas soluções.

---

## Visão geral da stack

```
┌─────────────────────────────────────────────────────┐
│                   docker-compose.yaml               │
├──────────────┬──────────────┬───────────────────────┤
│    rails     │    vite      │       sidekiq         │
│  :3000       │   :3036      │  (background jobs)    │
├──────────────┴──────────────┴───────────────────────┤
│    postgres (pgvector:pg16) │  redis  │  mailhog    │
└─────────────────────────────────────────────────────┘
```

| Serviço    | Porta | Descrição                                      | Como sobe         |
|------------|-------|------------------------------------------------|-------------------|
| `rails`    | 3000  | Servidor da API + backend                      | Build local       |
| `vite`     | 3036  | Servidor de assets do frontend (HMR)           | Build local       |
| `sidekiq`  | —     | Processamento de jobs em background            | Reutiliza `rails` |
| `postgres` | 5432  | Banco de dados (com suporte a pgvector)        | Pull Docker Hub   |
| `redis`    | 6379  | Cache e filas                                  | Pull Docker Hub   |
| `mailhog`  | 8025  | Captura de emails (UI web)                     | Pull Docker Hub   |

> `sidekiq` reutiliza a imagem do `rails` — não tem Dockerfile próprio.
> `postgres`, `redis` e `mailhog` são baixados automaticamente, não precisam de build.

---

## Configuração inicial (fazer uma vez)

### 1. Copiar o arquivo de variáveis de ambiente

```bash
cp .env.example .env
```

### 2. Editar o `.env`

Ajuste no mínimo as variáveis abaixo:

```bash
# Gere com: openssl rand -hex 64
SECRET_KEY_BASE=coloque_aqui_um_valor_hex_longo

# Conexão com o postgres do docker-compose
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=password   # deve ser igual ao docker-compose.yaml

# Redis
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=

# Mailhog para capturar emails localmente
SMTP_ADDRESS=mailhog
SMTP_PORT=1025

# URL do frontend
FRONTEND_URL=http://localhost:3000

# Ambiente — manter development para o Vite funcionar corretamente
RAILS_ENV=development
```

> **Importante**: o `POSTGRES_PASSWORD` no `.env` deve ser igual ao configurado no serviço `postgres` do `docker-compose.yaml`. Deixar vazio causa erro de inicialização do container.

### 3. Configurar senha do Postgres no `docker-compose.yaml`

No serviço `postgres`, certifique-se de que a senha não está vazia:

```yaml
postgres:
  environment:
    - POSTGRES_DB=chatwoot
    - POSTGRES_USER=postgres
    - POSTGRES_PASSWORD=password   # não pode ser vazio
```

> Versões recentes da imagem `pgvector/pgvector` exigem senha definida ou `POSTGRES_HOST_AUTH_METHOD=trust` explicitamente. Sem isso, o container reinicia em loop com erro `superuser password is not specified`.

### 4. Build das imagens

As imagens `rails` e `vite` dependem da imagem `base` — o build deve ser feito em ordem:

```bash
# Primeiro a imagem base (leva vários minutos na primeira vez)
docker compose build base

# Depois as imagens que dependem dela
docker compose build rails vite
```

> **Atenção**: rodar `docker compose build` sem especificar o serviço tenta buildar tudo em paralelo e falha porque `rails` e `vite` tentam usar `chatwoot:development` antes de ela existir.

---

## Setup do banco de dados

### Por que usar `db:schema:load` em vez de `db:migrate`

| Comando | O que faz | Quando usar |
|---------|-----------|-------------|
| `db:migrate` | Roda cada migration em ordem cronológica | Ambiente existente com dados |
| `db:schema:load` | Carrega o `db/schema.rb` diretamente (estado final) | Setup inicial (ambiente novo) |

> O `db:migrate` falha neste projeto porque uma migration de 2023 (`20231211010807`) referencia `ActsAsTaggableOn::Taggable::Cache`, uma constante que não existe mais na versão atual da gem. O `db:schema:load` pula esse problema carregando o schema final diretamente.

---

## Setup completo — banco zerado com onboarding (recomendado)

Esta é a sequência correta para iniciar do zero com o fluxo de onboarding:

```bash
# 1. Para tudo e apaga volumes (banco zerado)
docker compose down -v

# 2. Sobe só a infraestrutura
docker compose up -d postgres redis mailhog

# 3. Cria banco e carrega schema
docker compose run --rm rails bundle exec rails db:create db:schema:load

# 4. Carrega configs de instalação e ativa o onboarding no Redis
docker compose run --rm rails bundle exec rails runner \
  "ConfigLoader.new.process; Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)"

# 5. Sobe todos os serviços
docker compose up
```

Acesse **http://localhost:3000** — o onboarding vai aparecer para criar o super admin.

> O passo 4 substitui o `db:seed`. Explicação detalhada na seção sobre seeds abaixo.

---

## Sobre o `db:seed` e o onboarding

O comportamento do `db:seed` muda completamente dependendo do `RAILS_ENV`:

| RAILS_ENV | O que `db:seed` faz |
|-----------|---------------------|
| `production` | Define chave Redis que ativa o onboarding. Banco fica vazio. |
| `development` | Cria contas, usuários, inboxes e conversas de exemplo. **Onboarding não aparece.** |

**Credenciais criadas pelo seed de development:**
- Email: `john@acme.inc`
- Senha: `Password1!`

**Por que não usar `RAILS_ENV=production` no docker-compose:**
O `config/vite.json` não tem seção `production`. Em production, o Vite-Ruby espera assets pré-compilados (não um dev server), então o app retorna 500 ao tentar renderizar qualquer página. O docker-compose de desenvolvimento foi projetado para `RAILS_ENV=development`.

### Resumo: qual sequência usar

| Objetivo | Sequência |
|----------|-----------|
| Banco zerado + onboarding (recomendado) | `db:schema:load` + `rails runner` do passo 4 acima |
| Login direto com dados de exemplo | `db:schema:load` + `db:seed` |

---

## Fluxo de desenvolvimento diário

O código local é montado como volume (`./:/app:delegated`), então **mudanças nos arquivos refletem automaticamente**:

- **Ruby/Rails** → auto-reload pelo Rails
- **Vue/JS** → HMR automático pelo Vite (atualiza o browser sem recarregar)

### Iniciar

```bash
docker compose up
```

### Parar

```bash
docker compose down
```

> Na primeira inicialização após o build, o container do Vite executa `pnpm install --force` (baixa ~1094 pacotes). O app só responde corretamente após o Vite exibir `VITE ready in X ms`. Acompanhe com `docker compose logs -f vite`.

### Quando é necessário restart

| Situação | Ação |
|----------|------|
| Alteração em `.rb`, `.vue`, `.js` | Nenhuma — auto-reload |
| Adicionou gem no `Gemfile` | `docker compose restart rails sidekiq` |
| Adicionou pacote JS | `docker compose restart vite` |
| Alterou variável no `.env` | `docker compose down && docker compose up` |
| Alterou `docker-compose.yaml` | `docker compose down && docker compose up` |
| Alterou `Dockerfile` | Rebuild necessário (ver seção abaixo) |

---

## Comandos úteis

### Logs

```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f rails
docker compose logs -f vite
docker compose logs -f postgres
```

### Banco de dados

```bash
# Rodar migrations (ambiente existente com dados)
docker compose run --rm rails bundle exec rails db:migrate

# Abrir console do Rails
docker compose run --rm rails bundle exec rails c

# Resetar banco (apaga tudo e recria)
docker compose down -v
docker compose up -d postgres redis mailhog
docker compose run --rm rails bundle exec rails db:create db:schema:load
```

### Dependências

```bash
# Após adicionar gem ao Gemfile
docker compose run --rm rails bundle install
docker compose restart rails sidekiq

# Após adicionar pacote JS
docker compose run --rm vite pnpm install
docker compose restart vite
```

### Testes

```bash
# Rodar spec específico
docker compose run --rm rails bundle exec rspec spec/path/to/file_spec.rb

# Rodar linha específica
docker compose run --rm rails bundle exec rspec spec/path/to/file_spec.rb:NUMERO_DA_LINHA

# Lint Ruby
docker compose run --rm rails bundle exec rubocop -a

# Lint JS/Vue
docker compose run --rm vite pnpm eslint:fix
```

### Status dos containers

```bash
docker compose ps
```

---

## Quando rebuildar as imagens

| Situação | Comando |
|----------|---------|
| Mudança no `docker/Dockerfile` (base) | `docker compose build base && docker compose build rails vite` |
| Mudança no `Gemfile` / `Gemfile.lock` | `docker compose build rails` |
| Mudança no `package.json` / `pnpm-lock.yaml` | `docker compose build vite` |

Para mudanças no código Ruby ou Vue/JS do dia a dia, **não é necessário rebuildar**.

> Se as imagens `rails` e `vite` referenciarem `FROM chatwoot:development` nos seus Dockerfiles, o nome da imagem base no `docker-compose.yaml` deve ser `chatwoot:development`. Alterar os nomes das imagens no compose sem atualizar os Dockerfiles quebra o build.

---

## Problemas comuns e soluções

### Volume com estado corrompido (`file exists`)

```
failed to mkdir .../chatwoot_bundle/_data/build_info: file exists
```

Ocorre quando um container foi interrompido de forma inesperada e deixou o volume em estado inconsistente. Solução:

```bash
docker compose down
rm -rf ~/.local/share/docker/volumes/chatwoot_bundle
rm -rf ~/.local/share/docker/volumes/chatwoot_node_modules
rm -rf ~/.local/share/docker/volumes/chatwoot_packs
rm -rf ~/.local/share/docker/volumes/chatwoot_cache
```

> Em Docker rootless (sem sudo), os volumes ficam em `~/.local/share/docker/volumes/` e podem ser removidos diretamente pelo usuário.

### Postgres não inicializa (senha vazia)

```
Error: Database is uninitialized and superuser password is not specified.
```

Defina uma senha no `docker-compose.yaml` e no `.env`:

```yaml
# docker-compose.yaml
- POSTGRES_PASSWORD=password
```

```bash
# .env
POSTGRES_PASSWORD=password
```

Depois recrie o volume do postgres (que foi criado sem senha):

```bash
docker compose down -v
docker compose up -d postgres redis mailhog
```

### `db:migrate` falha com `uninitialized constant`

```
NameError: uninitialized constant ActsAsTaggableOn::Taggable::Cache
```

Migration histórica referencia código que não existe mais na gem atual. Use `db:schema:load` no lugar de `db:migrate` para setup inicial.

### App retorna 500 com `RAILS_ENV=production`

```
Vite Ruby can't find entrypoints/superadmin.js in the manifests.
autoBuild is set to false in your config/vite.json for this environment.
```

O `config/vite.json` não tem seção `production`. O docker-compose de desenvolvimento requer `RAILS_ENV=development`. Reverta o ambiente para `development` nos serviços `rails`, `vite` e `sidekiq`.

### Vite demora para responder no primeiro boot

O container do Vite executa `pnpm store prune` + `pnpm install --force` (~1094 pacotes) antes de subir o servidor. Aguarde a mensagem `VITE ready in X ms` nos logs antes de acessar o browser:

```bash
docker compose logs -f vite
```

### Volume em uso ao tentar remover

```
remove chatwoot_bundle: volume is in use
```

Pare os containers antes de remover volumes:

```bash
docker compose down
docker volume rm chatwoot_bundle
```

---

## Alternativa: DevContainer (Cursor / VS Code)

O projeto tem um `.devcontainer/` com uma imagem pré-compilada (`ghcr.io/chatwoot/chatwoot_codespace:latest`) que já tem Ruby, Node e dependências instaladas — economiza o tempo de build da imagem base. Instale a extensão **Dev Containers** no Cursor ou VS Code e abra o projeto dentro do container.
