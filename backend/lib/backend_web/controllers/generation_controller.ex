defmodule BackendWeb.GenerationController do
  @moduledoc """
  JSON API for creating and reading generated songs.

  This controller is designed for the Flutter app to call later.
  """

  use BackendWeb, :controller
  require Logger

  alias Backend.Music.Generation
  alias Backend.Music.MusicService

  def create(conn, params) do
    case MusicService.create_generation(params) do
      {:ok, response} ->
        conn
        |> put_status(:accepted)
        |> json(response)

      {:error, message} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: message})
    end
  end

  def show(conn, %{"id" => id}) do
    case MusicService.get_generation(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "generation not found"})

      generation ->
        json(conn, Generation.to_map(generation))
    end
  end

  def my_songs(conn, %{"user_id" => user_id}) do
    cleaned_user_id = String.trim(user_id)

    if cleaned_user_id == "" do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "user_id is required"})
    else
      tasks =
        cleaned_user_id
        |> MusicService.list_user_songs()
        |> Enum.map(&Generation.to_map/1)

      json(conn, %{tasks: tasks, songs: tasks})
    end
  end

  def my_songs(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "user_id is required"})
  end

  def suno_callback(conn, params) do
    Task.start(fn ->
      case MusicService.process_suno_callback(params) do
        :ok -> :ok
        {:error, message} -> Logger.warning("Suno callback ignored: #{message}")
      end
    end)

    json(conn, %{status: "received"})
  end
end
