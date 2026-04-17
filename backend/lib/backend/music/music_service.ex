defmodule Backend.Music.MusicService do
  @moduledoc """
  Main business logic for creating and reading generated songs.

  Controllers call this module instead of writing the generation logic directly.
  That keeps the code easy to read and easier to replace later.
  """

  alias Backend.Music.Generation
  alias Backend.Music.Store

  @default_duration 30
  @processing_delay_ms 3_000
  @demo_audio_urls [
    "https://samplelib.com/lib/preview/mp3/sample-3s.mp3",
    "https://samplelib.com/lib/preview/mp3/sample-6s.mp3",
    "https://samplelib.com/lib/preview/mp3/sample-12s.mp3"
  ]

  @doc """
  Creates a new generation request and starts a fake async job.
  """
  @spec create_generation(map()) :: {:ok, map()} | {:error, String.t()}
  def create_generation(params) when is_map(params) do
    with {:ok, prompt} <- validate_prompt(Map.get(params, "prompt")),
         user_id <- normalize_user_id(Map.get(params, "user_id")),
         duration_sec <- normalize_duration(Map.get(params, "duration_sec")) do
      now = now_utc()
      id = build_id()

      generation =
        %Generation{
          id: id,
          user_id: user_id,
          title: nil,
          prompt: prompt,
          duration_sec: duration_sec,
          status: "processing",
          audio_url: nil,
          created_at: now,
          updated_at: now
        }
        |> Store.save()

      Task.start(fn ->
        Process.sleep(@processing_delay_ms)

        Store.update(generation.id, %{
          status: "completed",
          title: build_title(generation.prompt),
          audio_url: pick_demo_audio_url(generation.duration_sec),
          updated_at: now_utc()
        })
      end)

      {:ok, %{id: generation.id, status: generation.status}}
    end
  end

  @doc """
  Returns one generation by id.
  """
  @spec get_generation(String.t()) :: Generation.t() | nil
  def get_generation(id), do: Store.get(id)

  @doc """
  Returns all songs in memory.
  """
  @spec list_all_songs() :: [Generation.t()]
  def list_all_songs, do: Store.list_all()

  @doc """
  Returns all songs created by one user.
  """
  @spec list_user_songs(String.t()) :: [Generation.t()]
  def list_user_songs(user_id), do: Store.list_by_user(user_id)

  defp validate_prompt(prompt) when is_binary(prompt) do
    cleaned_prompt = String.trim(prompt)

    if cleaned_prompt == "" do
      {:error, "prompt must not be empty"}
    else
      {:ok, cleaned_prompt}
    end
  end

  defp validate_prompt(_prompt), do: {:error, "prompt must not be empty"}

  defp normalize_user_id(user_id) when is_binary(user_id) do
    user_id
    |> String.trim()
    |> case do
      "" -> "guest_user"
      cleaned_user_id -> cleaned_user_id
    end
  end

  defp normalize_user_id(_user_id), do: "guest_user"

  defp normalize_duration(duration_sec) when is_integer(duration_sec) do
    if duration_sec in 1..60, do: duration_sec, else: @default_duration
  end

  defp normalize_duration(duration_sec) when is_binary(duration_sec) do
    case Integer.parse(duration_sec) do
      {parsed_duration, ""} -> normalize_duration(parsed_duration)
      _result -> @default_duration
    end
  end

  defp normalize_duration(_duration_sec), do: @default_duration

  defp build_id do
    timestamp = System.os_time(:millisecond)
    random_suffix = Enum.random(100..999)
    "gen_#{timestamp}_#{random_suffix}"
  end

  defp build_title(prompt) do
    prompt
    |> String.split(",", parts: 2)
    |> List.first()
    |> String.trim()
    |> String.slice(0, 30)
    |> case do
      "" -> "AI - Untitled"
      short_prompt -> "AI - #{short_prompt}"
    end
  end

  defp pick_demo_audio_url(duration_sec) when duration_sec <= 15, do: Enum.at(@demo_audio_urls, 0)
  defp pick_demo_audio_url(duration_sec) when duration_sec <= 30, do: Enum.at(@demo_audio_urls, 1)
  defp pick_demo_audio_url(_duration_sec), do: Enum.at(@demo_audio_urls, 2)

  defp now_utc do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end
end
