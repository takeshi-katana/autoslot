defmodule Autoslot.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AutoslotWeb.Telemetry,
      Autoslot.Repo,
      {DNSCluster, query: Application.get_env(:autoslot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Autoslot.PubSub},
      # Start a worker by calling: Autoslot.Worker.start_link(arg)
      # {Autoslot.Worker, arg},
      # Start to serve requests, typically the last entry
      AutoslotWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Autoslot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AutoslotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
