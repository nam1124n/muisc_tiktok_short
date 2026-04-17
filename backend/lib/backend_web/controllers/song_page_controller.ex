defmodule BackendWeb.SongPageController do
  @moduledoc """
  Admin pages for browsing and managing generated songs in the browser.
  """

  use BackendWeb, :controller

  alias Backend.Music.Generation
  alias Backend.Music.MusicService

  @default_duration 30
  @dashboard_user_limit 5
  @dashboard_song_limit 6

  def index(conn, _params) do
    all_songs = list_song_maps()
    overall_stats = build_stats(all_songs)
    user_summaries = build_user_summaries(all_songs)

    render(conn, :index,
      page_title: "Song Dashboard",
      overall_stats: overall_stats,
      top_users: Enum.take(user_summaries, @dashboard_user_limit),
      recent_songs: Enum.take(all_songs, @dashboard_song_limit),
      songs_empty?: Enum.empty?(all_songs)
    )
  end

  def library(conn, params) do
    filters = normalize_filters(params)
    all_songs = list_song_maps()
    filtered_songs = apply_filters(all_songs, filters)

    render(conn, :library,
      page_title: "Song Library",
      songs: filtered_songs,
      user_groups: build_user_groups(filtered_songs),
      users: build_user_summaries(all_songs),
      stats: build_stats(filtered_songs),
      overall_stats: build_stats(all_songs),
      filters: filters,
      has_filters: has_filters?(filters),
      status_options: MusicService.status_options()
    )
  end

  def show(conn, %{"id" => id}) do
    case MusicService.get_generation(id) do
      nil ->
        not_found(conn)

      generation ->
        render(conn, :show,
          page_title: "Song Detail",
          song: Generation.to_map(generation),
          user_filter_path: build_library_path(generation.user_id)
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    case MusicService.get_generation(id) do
      nil ->
        not_found(conn)

      generation ->
        song = Generation.to_map(generation)

        render_form(conn,
          page_title: "Edit Song",
          form_title: "Chỉnh sửa bài hát",
          form_description: "Cập nhật metadata, chủ sở hữu và trạng thái bài hát.",
          submit_label: "Lưu thay đổi",
          submit_path: ~p"/songs/#{song.id}",
          back_path: ~p"/songs/#{song.id}",
          song: song,
          errors: %{},
          status: :ok
        )
    end
  end

  def update(conn, %{"id" => id, "song" => song_params}) do
    case MusicService.update_song(id, song_params) do
      {:ok, generation} ->
        conn
        |> put_flash(:info, "Đã cập nhật bài hát.")
        |> redirect(to: ~p"/songs/#{generation.id}")

      {:error, errors} ->
        render_form(conn,
          page_title: "Edit Song",
          form_title: "Chỉnh sửa bài hát",
          form_description: "Kiểm tra lại thông tin trước khi lưu.",
          submit_label: "Lưu thay đổi",
          submit_path: ~p"/songs/#{id}",
          back_path: ~p"/songs/#{id}",
          song: song_form_data(Map.put(song_params, "id", id)),
          errors: errors,
          status: :unprocessable_entity
        )

      :not_found ->
        not_found(conn)
    end
  end

  def update(conn, %{"id" => _id}) do
    not_found(conn, "Song payload is required")
  end

  def delete(conn, %{"id" => id}) do
    case MusicService.delete_song(id) do
      nil ->
        not_found(conn)

      generation ->
        conn
        |> put_flash(:info, "Đã xóa bài hát.")
        |> redirect(to: build_library_path(generation.user_id))
    end
  end

  defp list_song_maps do
    MusicService.list_all_songs()
    |> Enum.map(&Generation.to_map/1)
  end

  defp normalize_filters(params) do
    %{
      user_id:
        params
        |> Map.get("user_id", "")
        |> String.trim(),
      status:
        params
        |> Map.get("status", "")
        |> String.trim()
    }
  end

  defp apply_filters(songs, filters) do
    songs
    |> maybe_filter_user(filters.user_id)
    |> maybe_filter_status(filters.status)
  end

  defp maybe_filter_user(songs, ""), do: songs

  defp maybe_filter_user(songs, user_filter) do
    normalized_filter = String.downcase(user_filter)

    Enum.filter(songs, fn song ->
      song.user_id
      |> String.downcase()
      |> String.contains?(normalized_filter)
    end)
  end

  defp maybe_filter_status(songs, ""), do: songs
  defp maybe_filter_status(songs, status), do: Enum.filter(songs, &(&1.status == status))

  defp build_stats(songs) do
    %{
      total: length(songs),
      users: songs |> Enum.map(& &1.user_id) |> Enum.uniq() |> length(),
      processing: Enum.count(songs, &(&1.status == "processing")),
      completed: Enum.count(songs, &(&1.status == "completed"))
    }
  end

  defp build_user_groups(songs) do
    songs
    |> Enum.group_by(& &1.user_id)
    |> Enum.map(fn {user_id, user_songs} ->
      %{
        user_id: user_id,
        songs: user_songs,
        total: length(user_songs),
        processing: Enum.count(user_songs, &(&1.status == "processing")),
        completed: Enum.count(user_songs, &(&1.status == "completed"))
      }
    end)
    |> Enum.sort_by(fn group -> {-group.total, group.user_id} end)
  end

  defp build_user_summaries(songs) do
    songs
    |> build_user_groups()
    |> Enum.map(fn group ->
      %{
        user_id: group.user_id,
        total: group.total,
        completed: group.completed
      }
    end)
  end

  defp has_filters?(filters), do: filters.user_id != "" or filters.status != ""

  defp song_form_data(params) do
    %{
      id: Map.get(params, "id") || Map.get(params, :id),
      user_id: Map.get(params, "user_id") || Map.get(params, :user_id) || "",
      title: Map.get(params, "title") || Map.get(params, :title) || "",
      prompt: Map.get(params, "prompt") || Map.get(params, :prompt) || "",
      duration_sec:
        Map.get(params, "duration_sec") || Map.get(params, :duration_sec) || @default_duration,
      status: Map.get(params, "status") || Map.get(params, :status) || "completed",
      audio_url: Map.get(params, "audio_url") || Map.get(params, :audio_url) || ""
    }
  end

  defp render_form(conn, assigns) do
    assigns = Map.new(assigns)

    conn
    |> put_status(assigns.status)
    |> render(
      :form,
      Map.delete(assigns, :status) |> Map.put(:status_options, MusicService.status_options())
    )
  end

  defp build_library_path(nil), do: ~p"/songs/library"
  defp build_library_path(""), do: ~p"/songs/library"
  defp build_library_path(user_id), do: ~p"/songs/library?user_id=#{user_id}"

  defp not_found(conn, message \\ "Song not found") do
    conn
    |> put_status(:not_found)
    |> text(message)
  end
end
