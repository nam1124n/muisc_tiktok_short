defmodule BackendWeb.GenerationControllerTest do
  use BackendWeb.ConnCase, async: false

  test "POST /api/generate creates a processing record", %{conn: conn} do
    conn =
      post(conn, ~p"/api/generate", %{
        user_id: "uid_001",
        prompt: "lofi chill piano, rainy night",
        duration_sec: 30
      })

    response = json_response(conn, 202)

    assert String.starts_with?(response["id"], "gen_")
    assert response["status"] == "processing"
  end

  test "POST /api/generate validates prompt", %{conn: conn} do
    conn =
      post(conn, ~p"/api/generate", %{
        user_id: "uid_001",
        prompt: "   ",
        duration_sec: 30
      })

    assert json_response(conn, 422) == %{"error" => "prompt must not be empty"}
  end
end
