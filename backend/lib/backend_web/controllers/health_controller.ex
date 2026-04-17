defmodule BackendWeb.HealthController do
  @moduledoc """
  Simple health check endpoint for web and API routes.
  """

  use BackendWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok"})
  end
end
