defmodule BackendWeb.Plugs.CORS do
  @moduledoc """
  Very small CORS plug for local Flutter web development.

  We keep it simple on purpose: allow any origin in development so the
  browser can call the Phoenix API from another localhost port.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn =
      conn
      |> put_resp_header("access-control-allow-origin", "*")
      |> put_resp_header("access-control-allow-methods", "GET,POST,OPTIONS")
      |> put_resp_header(
        "access-control-allow-headers",
        "content-type,authorization,accept,origin"
      )
      |> put_resp_header("access-control-max-age", "86400")

    if conn.method == "OPTIONS" do
      conn
      |> send_resp(:no_content, "")
      |> halt()
    else
      conn
    end
  end
end
