# Executando o Chatwoot com Docker

Guia para rodar o projeto localmente usando Docker, sem necessidade de instalar Ruby ou dependências do sistema.

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

| Serviço    | Porta | Descrição                                      |
|------------|-------|------------------------------------------------|
| `rails`    | 3000  | Servidor da API + backend                      |
| `vite`     | 3036  | Servidor de assets do frontend (HMR)           |
| `sidekiq`  | —     | Processamento de jobs em background            |
| `postgres` | 5432  | Banco de dados (com suporte a pgvector)        |
| `redis`    | 6379  | Cache e filas                                  |
| `mailhog`  | 8025  | Captura de emails no desenvolvimento (UI web)  |

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

# Já corretas para o docker-compose — não alterar:
POSTGRES_HOST=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=

# Mailhog para capturar emails localmente:
SMTP_ADDRESS=mailhog
SMTP_PORT=1025

FRONTEND_URL=http://localhost:3000
RAILS_ENV=development
```

### 3. Build das imagens

Na primeira vez leva alguns minutos (compila Ruby, Node, gems, pnpm).

As imagens `rails` e `vite` dependem da imagem `base`, então o build deve ser feito em ordem:

```bash
# Primeiro a imagem base
docker compose build base

# Depois as imagens que dependem dela
docker compose build rails vite
```

### 4. Subir a infraestrutura

```bash
docker compose up -d postgres redis mailhog
```

### 5. Criar e migrar o banco de dados

```bash
docker compose run --rm rails bundle exec rails db:create db:migrate
```

Opcional (Caso o comando não rode)
```bash
docker compose run --rm rails bundle exec rails db:create db:schema:load
```

**Observação**: Lembre-se de limpar os volumes
```bash
docker compose down

rm -rf ~/.local/share/docker/volumes/chatwoot_bundle
rm -rf ~/.local/share/docker/volumes/chatwoot_node_modules
rm -rf ~/.local/share/docker/volumes/chatwoot_packs
rm -rf ~/.local/share/docker/volumes/chatwoot_cache

docker volume rm chatwoot_bundle chatwoot_node_modules chatwoot_packs chatwoot_cache
```
Em produção pela primeira vez
```bash
docker compose down -v
docker compose up -d postgres redis mailhog
docker compose run --rm rails bundle exec rails db:create db:schema:load
docker compose run --rm rails bundle exec rails db:seed
docker compose up
```

Em development pela primeira vez
```bash
# 1. Limpa tudo
docker compose down -v

# 2. Sobe infraestrutura
docker compose up -d postgres redis mailhog

# 3. Cria banco e carrega schema
docker compose run --rm rails bundle exec rails db:create db:schema:load

# 4. Carrega configs de instalação e ativa o onboarding
docker compose run --rm rails bundle exec rails runner \
  "ConfigLoader.new.process; Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)"

# 5. Sobe tudo
docker compose up
```

### 6. (Opcional) Popular com dados iniciais

```bash
# Dados mínimos para verificação de features
docker compose run --rm rails bundle exec rails db:seed
```

### 7. Subir todos os serviços

```bash
docker compose up
```

A aplicação estará disponível em: **http://localhost:3000**

---

## Fluxo de desenvolvimento diário

O código local é montado como volume dentro dos containers (`./:/app:delegated`), então **qualquer mudança nos arquivos é refletida automaticamente**:

- Mudanças em **Ruby/Rails** → auto-reload pelo Rails
- Mudanças em **Vue/JS** → HMR automático pelo Vite

### Iniciar o ambiente

```bash
docker compose up
```

### Parar o ambiente

```bash
docker compose down
```

---

## Comandos úteis

### Logs

```bash
# Todos os serviços
docker compose logs -f

# Apenas o Rails
docker compose logs -f rails

# Apenas o Vite
docker compose logs -f vite
```

### Banco de dados

```bash
# Rodar migrations
docker compose run --rm rails bundle exec rails db:migrate

# Abrir console do Rails
docker compose run --rm rails bundle exec rails c

# Resetar banco de dados
docker compose run --rm rails bundle exec rails db:drop db:create db:migrate db:seed
```

### Dependências

```bash
# Após adicionar uma gem ao Gemfile
docker compose run --rm rails bundle install

# Após adicionar um pacote JS
docker compose run --rm vite pnpm install
```

### Testes

```bash
# Rodar arquivo de spec específico
docker compose run --rm rails bundle exec rspec spec/path/to/file_spec.rb

# Rodar linha específica
docker compose run --rm rails bundle exec rspec spec/path/to/file_spec.rb:NUMERO_DA_LINHA

# Lint Ruby
docker compose run --rm rails bundle exec rubocop -a

# Lint JS/Vue
docker compose run --rm vite pnpm eslint:fix
```

### Limpeza

```bash
# Parar e remover containers (mantém volumes/banco)
docker compose down

# Parar, remover containers E volumes (apaga banco de dados)
docker compose down -v

# Rebuildar uma imagem específica após mudanças no Dockerfile
docker compose build rails
docker compose build vite
```

---

## Quando rebuildar as imagens

Rebuildar só é necessário quando houver mudanças no próprio `Dockerfile` ou nos arquivos de dependência antes do `COPY . /app`:

| Situação                                    | Comando                                             |
|---------------------------------------------|-----------------------------------------------------|
| Mudança no `Dockerfile` (base)              | `docker compose build base && docker compose build rails vite` |
| Mudança no `Gemfile` / `Gemfile.lock`       | `docker compose build rails`                        |
| Mudança no `package.json` / `pnpm-lock.yaml`| `docker compose build vite`                         |

Para mudanças no código Ruby ou Vue/JS do dia a dia, **não é necessário rebuildar**.

---

## Alternativa: DevContainer (Cursor / VS Code)

O projeto tem um `.devcontainer/` configurado que usa uma imagem pré-compilada (`ghcr.io/chatwoot/chatwoot_codespace:latest`) com Ruby, Node e todas as dependências já instaladas — economiza tempo de build. Para usar, instale a extensão **Dev Containers** no Cursor ou VS Code e abra o projeto dentro do container.
