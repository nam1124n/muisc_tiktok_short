defmodule BackendWeb.PageControllerTest do
  use BackendWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/songs"
  end
end
