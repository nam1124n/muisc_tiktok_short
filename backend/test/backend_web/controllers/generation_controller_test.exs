defmodule BackendWeb.GenerationControllerTest do
  use BackendWeb.ConnCase, async: false

  alias Backend.Music.Store

  setup do
    Store.clear()
    :ok
  end

  test "POST /api/generate creates a processing record", %{conn: conn} do
    conn =
      post(conn, ~p"/api/generate", %{
        user_id: "uid_001",
        prompt: "lofi chill piano, rainy night"
      })

    response = json_response(conn, 202)

    assert String.starts_with?(response["taskId"], "gen_")
    assert response["status"] == "processing"
    assert response["outputCount"] == 2
  end

  test "POST /api/generate validates prompt", %{conn: conn} do
    conn =
      post(conn, ~p"/api/generate", %{
        user_id: "uid_001",
        prompt: "   "
      })

    assert json_response(conn, 422) == %{"error" => "prompt must not be empty"}
  end

  test "POST /api/suno/callback accepts callback and updates generation", %{conn: conn} do
    create_conn =
      post(conn, ~p"/api/generate", %{
        user_id: "uid_001",
        prompt: "lofi chill piano, rainy night"
      })

    generation = json_response(create_conn, 202)
    task_id = generation["taskId"]

    callback_conn =
      post(conn, ~p"/api/suno/callback", %{
        "code" => 200,
        "msg" => "All generated successfully.",
        "data" => %{
          "callbackType" => "complete",
          "task_id" => task_id,
          "data" => [
            %{
              "id" => "track_001",
              "audio_url" => "https://example.com/audio.mp3",
              "stream_audio_url" => "https://example.com/stream",
              "image_url" => "https://example.com/cover.jpeg",
              "prompt" => "[Instrumental]",
              "model_name" => "chirp-crow",
              "title" => "Rain On The Window",
              "tags" => "lofi, soft",
              "createTime" => "2025-01-01 00:00:00",
              "duration" => 134.92
            }
          ]
        }
      })

    assert json_response(callback_conn, 200) == %{"status" => "received"}

    Process.sleep(50)

    updated_generation = Store.get(task_id)
    assert updated_generation.status == "success"
    assert updated_generation.title == "Rain On The Window"
    assert length(updated_generation.tracks) == 1
    assert hd(updated_generation.tracks).audio_url == "https://example.com/audio.mp3"
  end
end
