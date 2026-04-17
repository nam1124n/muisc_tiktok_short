defmodule BackendWeb.SongPageControllerTest do
  use BackendWeb.ConnCase, async: false

  alias Backend.Music.MusicService
  alias Backend.Music.Store

  setup do
    Store.clear()
    :ok
  end

  test "GET /songs shows the dashboard summary", %{conn: conn} do
    {:ok, _song_one} =
      MusicService.create_song(%{
        "user_id" => "uid_alpha",
        "title" => "Morning Lofi",
        "prompt" => "lofi chill for early morning",
        "duration_sec" => 30,
        "status" => "completed",
        "audio_url" => "https://example.com/alpha.mp3"
      })

    {:ok, _song_two} =
      MusicService.create_song(%{
        "user_id" => "uid_beta",
        "title" => "Night Drive",
        "prompt" => "dark synthwave for late night driving",
        "duration_sec" => 45,
        "status" => "processing"
      })

    conn = get(conn, ~p"/songs")
    html = html_response(conn, 200)

    assert html =~ "AI Generation Dashboard"
    assert html =~ "Total Songs"
    assert html =~ "Xem user + bài hát"
    assert html =~ "uid_alpha"
    assert html =~ "Morning Lofi"
  end

  test "GET /songs/library groups songs by user", %{conn: conn} do
    {:ok, _song_one} =
      MusicService.create_song(%{
        "user_id" => "uid_alpha",
        "title" => "Morning Lofi",
        "prompt" => "lofi chill for early morning",
        "duration_sec" => 30,
        "status" => "completed",
        "audio_url" => "https://example.com/alpha.mp3"
      })

    {:ok, _song_two} =
      MusicService.create_song(%{
        "user_id" => "uid_beta",
        "title" => "Night Drive",
        "prompt" => "dark synthwave for late night driving",
        "duration_sec" => 45,
        "status" => "processing"
      })

    conn = get(conn, ~p"/songs/library")
    html = html_response(conn, 200)

    assert html =~ "AI Generation Library"
    assert html =~ "uid_alpha"
    assert html =~ "uid_beta"
    assert html =~ "Morning Lofi"
    assert html =~ "Night Drive"
  end

  test "PATCH /songs/:id updates a song", %{conn: conn} do
    {:ok, song} =
      MusicService.create_song(%{
        "user_id" => "uid_edit",
        "title" => "Before Edit",
        "prompt" => "original prompt",
        "duration_sec" => 30,
        "status" => "processing"
      })

    conn =
      patch(conn, ~p"/songs/#{song.id}", %{
        "song" => %{
          "user_id" => "uid_edit",
          "title" => "After Edit",
          "prompt" => "updated prompt",
          "duration_sec" => "60",
          "status" => "completed",
          "audio_url" => "https://example.com/updated.mp3"
        }
      })

    assert redirected_to(conn) == ~p"/songs/#{song.id}"

    conn = get(recycle(conn), ~p"/songs/#{song.id}")
    html = html_response(conn, 200)

    assert html =~ "After Edit"
    assert html =~ "updated prompt"
    assert html =~ "https://example.com/updated.mp3"
  end

  test "DELETE /songs/:id removes a song", %{conn: conn} do
    {:ok, song} =
      MusicService.create_song(%{
        "user_id" => "uid_delete",
        "title" => "Delete Me",
        "prompt" => "to be removed from the dashboard",
        "duration_sec" => 30,
        "status" => "completed"
      })

    conn = delete(conn, ~p"/songs/#{song.id}")

    assert redirected_to(conn) == ~p"/songs/library?user_id=uid_delete"

    conn = get(recycle(conn), ~p"/songs/library")
    html = html_response(conn, 200)

    refute html =~ "Delete Me"
  end
end
