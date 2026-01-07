defmodule TesseractStudio.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TesseractStudioWeb.Telemetry,
      TesseractStudio.Repo,
      # Run migrations automatically on startup
      {Ecto.Migrator,
       repos: Application.fetch_env!(:tesseract_studio, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:tesseract_studio, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TesseractStudio.PubSub},
      # Start a worker by calling: TesseractStudio.Worker.start_link(arg)
      # {TesseractStudio.Worker, arg},
      # Start to serve requests, typically the last entry
      TesseractStudioWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TesseractStudio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TesseractStudioWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations? do
    # Skip migrations during test to avoid conflicts with test setup
    Application.get_env(:tesseract_studio, :skip_migrations, false)
  end
end
