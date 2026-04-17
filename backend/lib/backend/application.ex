defmodule Backend.Application do
  @moduledoc """
  Entry point of the backend application.

  This file starts the in-memory store and the Phoenix endpoint.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Store generated songs in memory for the first project phase.
      Backend.Music.Store,
      BackendWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Backend.PubSub},
      BackendWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Backend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
