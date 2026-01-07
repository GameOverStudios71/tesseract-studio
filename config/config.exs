# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :tesseract_studio, :scopes,
  user: [
    default: true,
    module: TesseractStudio.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: TesseractStudio.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :tesseract_studio,
  ecto_repos: [TesseractStudio.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :tesseract_studio, TesseractStudioWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TesseractStudioWeb.ErrorHTML, json: TesseractStudioWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TesseractStudio.PubSub,
  live_view: [signing_salt: "oAX7c8V5"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :tesseract_studio, TesseractStudio.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  tesseract_studio: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=. --loader:.jsx=jsx),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  tesseract_studio: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure dart_sass for SCSS compilation
config :dart_sass,
  version: "1.77.8",
  tesseract_studio: [
    args: ~w(
      assets/css/main.scss
      priv/static/assets/css/main.css
      --load-path=assets/css
    ),
    cd: Path.expand("..", __DIR__)
  ],
  star_tickets: [
    args: ~w(
      star-tickets/assets/css/app.scss
      star-tickets/priv/static/assets/app.css
      --load-path=star-tickets/assets/css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
