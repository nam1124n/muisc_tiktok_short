defmodule BackendWeb.PageController do
  @moduledoc """
  Redirects the root path to the song management page.
  """

  use BackendWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/songs")
  end
end
