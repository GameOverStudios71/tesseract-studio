<p align="center">
  <img src="https://raw.githubusercontent.com/phoenixframework/phoenix/master/assets/logo.png" width="80" alt="Phoenix Logo"/>
</p>

<h1 align="center">🧊 TesseractStudio</h1>

<p align="center">
  <strong>Um construtor visual de páginas com editor node-based</strong>
</p>

<p align="center">
  <a href="#-sobre">Sobre</a> •
  <a href="#-tecnologias">Tecnologias</a> •
  <a href="#-arquitetura">Arquitetura</a> •
  <a href="#-instalação">Instalação</a> •
  <a href="#-uso">Uso</a> •
  <a href="#-estrutura">Estrutura</a> •
  <a href="#-desenvolvimento">Desenvolvimento</a>
</p>

---

## 📖 Sobre

**TesseractStudio** é uma aplicação web para criar e gerenciar páginas de forma visual usando um editor baseado em nós (nodes). Os usuários podem:

- 🎨 **Criar projetos** com múltiplas páginas interconectadas
- 🔗 **Conectar páginas** visualmente usando React Flow
- ✍️ **Editar conteúdo** com editor rich text TipTap
- 🌐 **Publicar páginas** com URLs amigáveis (`/p/{projeto}/{página}`)
- 📱 **Pré-visualizar** em diferentes dispositivos (desktop, tablet, mobile)

### Principais Funcionalidades

| Funcionalidade | Descrição |
|----------------|-----------|
| **Visual Builder** | Interface drag-and-drop com React Flow para criar fluxos de páginas |
| **Editor Rich Text** | TipTap editor com formatação, links, imagens e alinhamento |
| **Autenticação Magic Link** | Login sem senha via email |
| **Multi-dispositivo** | Preview responsivo integrado |
| **URLs Públicas** | Páginas acessíveis sem login |

---

## 🛠 Tecnologias

### Backend
| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| **Elixir** | ~> 1.15 | Linguagem funcional baseada em Erlang |
| **Phoenix** | ~> 1.8.3 | Framework web em tempo real |
| **Phoenix LiveView** | ~> 1.1.0 | Interfaces dinâmicas server-rendered |
| **Ecto** | ~> 3.13 | ORM e validação de dados |
| **PostgreSQL** | 14+ | Banco de dados relacional |
| **Bcrypt** | ~> 3.0 | Hash de senhas |
| **Swoosh** | ~> 1.16 | Envio de emails |
| **Req** | ~> 0.5 | Cliente HTTP |

### Frontend
| Tecnologia | Versão | Descrição |
|------------|--------|-----------|
| **React** | ^18.3.1 | Biblioteca UI |
| **@xyflow/react** | ^12.3.0 | Editor node-based (React Flow) |
| **TipTap** | ^3.15.3 | Editor rich text WYSIWYG |
| **Tailwind CSS** | v4 | Framework CSS utility-first |
| **SCSS** | via dart_sass | Pré-processador CSS |
| **Lucide React** | ^0.562.0 | Ícones |
| **esbuild** | ~> 0.10 | Bundler JavaScript |

---

## 🏗 Arquitetura

### Visão Geral

```
┌─────────────────────────────────────────────────────────────────┐
│                         Browser                                  │
├─────────────────────────────────────────────────────────────────┤
│  Phoenix LiveView  ←→  React (via phx-hook)                     │
│  ┌──────────────┐     ┌──────────────┐  ┌──────────────┐       │
│  │  BuilderLive │────▶│  ReactFlow   │  │ TipTap Editor│       │
│  │  ProjectLive │     │  FlowEditor  │  │ContentEditor │       │
│  │  PageLive    │     └──────────────┘  └──────────────┘       │
│  └──────────────┘                                               │
├─────────────────────────────────────────────────────────────────┤
│                      Phoenix Framework                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Router     │  │  Contexts    │  │   Schemas    │          │
│  │              │  │  - Accounts  │  │  - User      │          │
│  │  /projects   │  │  - Studio    │  │  - Project   │          │
│  │  /builder    │  │              │  │  - Page      │          │
│  │  /p/:slug    │  │              │  │  - Edge      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
├─────────────────────────────────────────────────────────────────┤
│                       PostgreSQL                                 │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │ users  │  │projects│  │ pages  │  │ edges  │  │ tokens │   │
│  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Contexts (Bounded Contexts)

#### 1. Accounts (`lib/tesseract_studio/accounts.ex`)
Gerencia autenticação e usuários:
- Registro de usuários
- Login via Magic Link (passwordless)
- Gestão de sessões e tokens
- Configurações de conta

#### 2. Studio (`lib/tesseract_studio/studio.ex`)
Lógica principal do builder:
- CRUD de projetos
- CRUD de páginas
- Gerenciamento de edges (conexões)
- Serialização para React Flow

### Schemas (Modelos de Dados)

```elixir
# Project - Container principal
schema "projects" do
  field :name, :string
  field :slug, :string        # URL-friendly, auto-gerado
  field :description, :string
  belongs_to :user, User
  has_many :pages, Page
  has_many :edges, Edge
end

# Page - Nó no canvas
schema "pages" do
  field :name, :string
  field :slug, :string
  field :content, :map        # JSON do TipTap
  field :node_id, :string     # ID para React Flow
  field :position_x, :float   # Posição X no canvas
  field :position_y, :float   # Posição Y no canvas
  belongs_to :project, Project
end

# Edge - Conexão entre páginas
schema "edges" do
  field :edge_id, :string     # ID para React Flow
  field :label, :string
  belongs_to :source_page, Page
  belongs_to :target_page, Page
  belongs_to :project, Project
end
```

### Rotas

| Método | Rota | LiveView/Controller | Autenticação |
|--------|------|---------------------|--------------|
| GET | `/` | PageController | Pública |
| GET | `/projects` | ProjectLive.Index | Requerida |
| GET | `/projects/:id/builder` | BuilderLive | Requerida |
| GET | `/p/:project_slug/:page_slug` | PageLive.Show | Pública |
| GET | `/users/register` | UserLive.Registration | Pública |
| GET | `/users/log-in` | UserLive.Login | Pública |
| GET | `/users/settings` | UserLive.Settings | Requerida |
| GET | `/dev/dashboard` | LiveDashboard | Dev only |
| GET | `/dev/mailbox` | Swoosh Mailbox | Dev only |

---

## 🚀 Instalação

### Pré-requisitos

- **Erlang** 26+
- **Elixir** 1.15+
- **Node.js** 18+
- **PostgreSQL** 14+

### Passos

1. **Clone o repositório**
```bash
git clone https://github.com/seu-usuario/tesseract-studio.git
cd tesseract-studio
```

2. **Instale dependências Elixir**
```bash
mix deps.get
```

3. **Instale dependências JavaScript**
```bash
cd assets && npm install && cd ..
```

4. **Configure o banco de dados**

Edite `config/dev.exs` com suas credenciais:
```elixir
config :tesseract_studio, TesseractStudio.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "tesseract_studio_dev"
```

5. **Setup completo**
```bash
mix setup
```

Isso executa:
- `mix deps.get` - Baixa dependências
- `mix ecto.setup` - Cria banco, executa migrations e seeds
- `mix assets.setup` - Instala Tailwind, esbuild, Sass
- `mix assets.build` - Compila assets

6. **Inicie o servidor**
```bash
mix phx.server
```

Acesse [`localhost:4000`](http://localhost:4000)

---

## 📱 Uso

### Fluxo Básico

1. **Registrar-se** - Acesse `/users/register` e insira seu email
2. **Login** - Receba o magic link por email e clique para entrar
3. **Criar Projeto** - Em `/projects`, clique em "New Project"
4. **Usar o Builder** - Adicione páginas arrastando nodes no canvas
5. **Editar Páginas** - Clique no link de uma página para editar conteúdo
6. **Publicar** - Acesse `/p/{projeto-slug}/{pagina-slug}` para ver a página pública

### Atalhos no Builder

| Ação | Descrição |
|------|-----------|
| Clique + Arraste | Move nodes |
| Conectar handles | Cria edge entre páginas |
| Delete/Backspace | Remove node/edge selecionado |
| Scroll | Zoom in/out |
| Arrastar canvas | Pan |

---

## 📁 Estrutura do Projeto

```
tesseract-studio/
├── assets/                          # Frontend assets
│   ├── css/
│   │   ├── app.css                  # Tailwind CSS v4 entry
│   │   ├── main.scss                # SCSS entry point
│   │   ├── base/                    # Reset, variáveis, premium styles
│   │   ├── components/              # Estilos de componentes
│   │   └── layout/                  # Estilos de layout
│   ├── js/
│   │   ├── app.js                   # JavaScript entry point
│   │   ├── hooks/
│   │   │   ├── react_flow_hook.js   # Hook para React Flow
│   │   │   └── content_editor_hook.js # Hook para TipTap
│   │   └── react/
│   │       ├── FlowEditor.jsx       # Componente React Flow
│   │       └── ContentEditor.jsx    # Componente TipTap
│   ├── vendor/                      # Libs externas (topbar)
│   └── package.json
│
├── config/
│   ├── config.exs                   # Configuração base
│   ├── dev.exs                      # Configuração desenvolvimento
│   ├── prod.exs                     # Configuração produção
│   ├── runtime.exs                  # Configuração runtime
│   └── test.exs                     # Configuração testes
│
├── lib/
│   ├── tesseract_studio/            # Lógica de negócio (Contexts)
│   │   ├── accounts/                # Schema User, UserToken, UserNotifier
│   │   ├── accounts.ex              # Context de autenticação
│   │   ├── studio/                  # Schema Project, Page, Edge
│   │   ├── studio.ex                # Context principal do builder
│   │   ├── application.ex           # Supervisão OTP
│   │   ├── mailer.ex                # Configuração Swoosh
│   │   └── repo.ex                  # Ecto Repo
│   │
│   ├── tesseract_studio_web/        # Camada Web
│   │   ├── components/
│   │   │   ├── core_components.ex   # Componentes Phoenix (input, button, modal)
│   │   │   ├── layouts.ex           # Layouts (app, root, public)
│   │   │   └── layouts/             # Templates de layout (.heex)
│   │   ├── controllers/             # Controllers HTTP
│   │   ├── live/
│   │   │   ├── builder_live.ex      # Visual node editor
│   │   │   ├── project_live/        # Listagem de projetos
│   │   │   ├── page_live/           # Visualização/edição de página
│   │   │   └── user_live/           # Registro, login, settings
│   │   ├── router.ex                # Rotas da aplicação
│   │   ├── endpoint.ex              # Phoenix Endpoint
│   │   ├── user_auth.ex             # Plugs e hooks de autenticação
│   │   └── telemetry.ex             # Métricas
│   │
│   ├── tesseract_studio.ex          # Módulo raiz
│   └── tesseract_studio_web.ex      # Helpers e imports Web
│
├── priv/
│   ├── gettext/                     # Traduções
│   ├── repo/
│   │   ├── migrations/              # Migrações Ecto
│   │   └── seeds.exs                # Dados iniciais
│   └── static/                      # Assets estáticos
│
├── test/                            # Testes
├── AGENTS.md                        # Guidelines para desenvolvimento
├── mix.exs                          # Configuração do projeto Elixir
└── README.md
```

---

## 💻 Desenvolvimento

### Comandos Úteis

```bash
# Servidor de desenvolvimento
mix phx.server

# Console interativo com app carregado
iex -S mix

# Executar testes
mix test

# Executar teste específico
mix test test/tesseract_studio/studio_test.exs

# Executar testes falhos
mix test --failed

# Pre-commit (format, compile, test)
mix precommit

# Criar migration
mix ecto.gen.migration nome_da_migration

# Executar migrations
mix ecto.migrate

# Rollback última migration
mix ecto.rollback

# Reset banco de dados
mix ecto.reset

# Compilar assets
mix assets.build

# Deploy assets (minified)
mix assets.deploy
```

### Variáveis de Ambiente (Produção)

```bash
# Obrigatórias
SECRET_KEY_BASE=           # mix phx.gen.secret
DATABASE_URL=              # postgres://user:pass@host:5432/db
PHX_HOST=                  # exemplo.com

# Opcionais
POOL_SIZE=10               # Conexões do banco
PORT=4000                  # Porta HTTP
```

### Guidelines de Código

O arquivo `AGENTS.md` contém diretrizes detalhadas:

- **Phoenix 1.8**: Sempre use `<Layouts.app>` nos templates LiveView
- **Tailwind v4**: Nova sintaxe de import, sem `tailwind.config.js`
- **LiveView**: Use streams para coleções, evite LiveComponents desnecessários
- **Ecto**: Sempre preload associações usadas em templates
- **Formulários**: Use `to_form/2` e `<.input>`, nunca `@changeset` direto
- **Autenticação**: Use `@current_scope.user`, não `@current_user`

---

## 🧪 Testes

```bash
# Todos os testes
mix test

# Com cobertura
MIX_ENV=test mix test --cover

# Watch mode (requer fswatch)
mix test.watch
```

### Estrutura de Testes

```
test/
├── tesseract_studio/           # Testes de contextos
│   ├── accounts_test.exs
│   └── studio_test.exs
├── tesseract_studio_web/       # Testes de controllers/live
│   ├── controllers/
│   └── live/
└── support/                    # Fixtures e helpers
    ├── conn_case.ex
    ├── data_case.ex
    └── fixtures/
```

---

## 🚢 Deploy

### Build de Produção

```bash
# Compilar release
MIX_ENV=prod mix release

# Ou com Docker
docker build -t tesseract-studio .
docker run -p 4000:4000 tesseract-studio
```

### Plataformas Recomendadas

- **Fly.io** - Deploy simples com `fly launch`
- **Render** - Build automático com Dockerfile
- **Railway** - Git push to deploy
- **Gigalixir** - Especializado em Elixir

---

## 📄 Licença

Este projeto está sob licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Add nova feature'`)
4. Push para branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

<p align="center">
  Feito com ❤️ usando <a href="https://phoenixframework.org">Phoenix Framework</a>
</p>
