defmodule Backend.Music.Generation do
  @moduledoc """
  Defines the shape of one generated song record.

  For the first version, records are kept only in memory.
  Later you can map the same fields to Firestore or a database table.
  """

  defstruct [
    :id,
    :user_id,
    :title,
    :prompt,
    :duration_sec,
    :requested_duration_sec,
    :status,
    :audio_url,
    :image_url,
    :provider,
    :provider_account,
    :output_count,
    :tracks,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          user_id: String.t(),
          title: String.t() | nil,
          prompt: String.t(),
          duration_sec: integer(),
          requested_duration_sec: integer() | nil,
          status: String.t(),
          audio_url: String.t() | nil,
          image_url: String.t() | nil,
          provider: String.t() | nil,
          provider_account: String.t() | nil,
          output_count: integer() | nil,
          tracks: [map()] | nil,
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
  Converts the struct into a plain map for JSON responses and templates.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = generation) do
    tracks = normalize_tracks(generation)

    %{
      id: generation.id,
      task_id: generation.id,
      user_id: generation.user_id,
      title: generation.title,
      prompt: generation.prompt,
      duration_sec: generation.duration_sec,
      requested_duration_sec: generation.requested_duration_sec,
      status: generation.status,
      audio_url: generation.audio_url,
      image_url: generation.image_url,
      provider: generation.provider,
      provider_account: generation.provider_account,
      key_alias: generation.provider_account,
      output_count: generation.output_count || length(tracks),
      tracks: tracks,
      created_at: format_datetime(generation.created_at),
      updated_at: format_datetime(generation.updated_at)
    }
  end

  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp format_datetime(_value), do: nil

  defp normalize_tracks(%__MODULE__{tracks: tracks}) when is_list(tracks) and tracks != [] do
    Enum.map(tracks, &format_track/1)
  end

  defp normalize_tracks(%__MODULE__{} = generation) do
    if generation.audio_url do
      [
        %{
          id: generation.id,
          variant_index: 0,
          title: generation.title,
          prompt: generation.prompt,
          duration_sec: generation.duration_sec,
          audio_url: generation.audio_url,
          image_url: generation.image_url,
          provider: generation.provider,
          provider_account: generation.provider_account,
          key_alias: generation.provider_account,
          created_at: format_datetime(generation.created_at)
        }
      ]
    else
      []
    end
  end

  defp format_track(track) when is_map(track) do
    %{
      id: Map.get(track, :id) || Map.get(track, "id"),
      variant_index: Map.get(track, :variant_index) || Map.get(track, "variant_index") || 0,
      title: Map.get(track, :title) || Map.get(track, "title"),
      prompt: Map.get(track, :prompt) || Map.get(track, "prompt"),
      duration_sec: Map.get(track, :duration_sec) || Map.get(track, "duration_sec") || 0,
      audio_url: Map.get(track, :audio_url) || Map.get(track, "audio_url"),
      stream_audio_url: Map.get(track, :stream_audio_url) || Map.get(track, "stream_audio_url"),
      image_url: Map.get(track, :image_url) || Map.get(track, "image_url"),
      provider: Map.get(track, :provider) || Map.get(track, "provider"),
      provider_account: Map.get(track, :provider_account) || Map.get(track, "provider_account"),
      key_alias: Map.get(track, :provider_account) || Map.get(track, "provider_account"),
      model_name: Map.get(track, :model_name) || Map.get(track, "model_name"),
      tags: Map.get(track, :tags) || Map.get(track, "tags") || [],
      created_at: format_datetime(Map.get(track, :created_at) || Map.get(track, "created_at"))
    }
  end
end
