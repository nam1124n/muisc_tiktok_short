defmodule BackendWeb.SongPageController do
  @moduledoc """
  Basic admin pages for browsing generated songs in the browser.
  """

  use BackendWeb, :controller

  alias Backend.Music.Generation
  alias Backend.Music.MusicService

  def index(conn, _params) do
    songs =
      MusicService.list_all_songs()
      |> Enum.map(&Generation.to_map/1)

    stats = %{
      total: length(songs),
      processing: Enum.count(songs, &(&1.status == "processing")),
      completed: Enum.count(songs, &(&1.status == "completed"))
    }

    render(conn, :index, page_title: "Generated Songs", songs: songs, stats: stats)
  end

  def show(conn, %{"id" => id}) do
    case MusicService.get_generation(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("Song not found")

      generation ->
        render(conn, :show,
          page_title: "Song Detail",
          song: Generation.to_map(generation)
        )
    end
  end
end
