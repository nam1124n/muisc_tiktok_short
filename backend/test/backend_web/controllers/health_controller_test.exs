defmodule BackendWeb.HealthControllerTest do
  use BackendWeb.ConnCase, async: true

  test "GET /health", %{conn: conn} do
    conn = get(conn, ~p"/health")

    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "GET /api/health", %{conn: conn} do
    conn = get(conn, ~p"/api/health")

    assert json_response(conn, 200) == %{"status" => "ok"}
  end
end
