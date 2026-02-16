defmodule ShelleyPlants.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ShelleyPlantsWeb.Telemetry,
      ShelleyPlants.Repo,
      {DNSCluster, query: Application.get_env(:shelley_plants, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ShelleyPlants.PubSub},
      # Start a worker by calling: ShelleyPlants.Worker.start_link(arg)
      # {ShelleyPlants.Worker, arg},
      # Start to serve requests, typically the last entry
      ShelleyPlantsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShelleyPlants.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShelleyPlantsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
