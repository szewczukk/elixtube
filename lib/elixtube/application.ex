defmodule Elixtube.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Elixtube.TranscodeServer,
      ElixtubeWeb.Telemetry,
      Elixtube.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:elixtube, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:elixtube, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Elixtube.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Elixtube.Finch},
      # Start a worker by calling: Elixtube.Worker.start_link(arg)
      # {Elixtube.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixtubeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Elixtube.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixtubeWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
