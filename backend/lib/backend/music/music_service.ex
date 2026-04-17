defmodule Backend.Music.MusicService do
  @moduledoc """
  Main business logic for creating and reading generated songs.

  Controllers call this module instead of writing the generation logic directly.
  That keeps the code easy to read and easier to replace later.
  """

  require Logger

  alias Backend.Firebase.FirestoreClient
  alias Backend.Media.CloudinaryClient
  alias Backend.Music.Generation
  alias Backend.Music.SunoClient
  alias Backend.Music.Store

  @default_duration 30
  @allowed_statuses ~w(processing first_success success completed failed)
  @active_suno_statuses ~w(processing first_success)
  @processing_delay_ms 1_500
  @default_provider "mock-suno-api"
  @default_model "V5"
  @demo_audio_urls [
    "https://samplelib.com/lib/preview/mp3/sample-6s.mp3",
    "https://samplelib.com/lib/preview/mp3/sample-12s.mp3"
  ]

  @doc """
  Creates a new generation request and starts a fake async job.

  The fake job mirrors Suno's contract:
  one task id produces up to two generated tracks.
  """
  @spec create_generation(map()) :: {:ok, map()} | {:error, String.t()}
  def create_generation(params) when is_map(params) do
    with {:ok, prompt} <- validate_prompt(Map.get(params, "prompt")),
         user_id <- normalize_user_id(Map.get(params, "user_id")),
         requested_duration_sec <-
           normalize_requested_duration(
             Map.get(params, "requested_duration_sec") || Map.get(params, "duration_sec")
           ) do
      if SunoClient.enabled?() do
        create_suno_generation(prompt, user_id, requested_duration_sec)
      else
        create_mock_generation(prompt, user_id, requested_duration_sec)
      end
    end
  end

  @doc """
  Creates one song from the admin UI without async generation.
  """
  @spec create_song(map()) :: {:ok, Generation.t()} | {:error, map()}
  def create_song(params) when is_map(params) do
    with {:ok, attrs} <- normalize_song_attrs(params) do
      now = now_utc()

      generation =
        %Generation{
          id: build_id(),
          user_id: attrs.user_id,
          title: attrs.title,
          prompt: attrs.prompt,
          duration_sec: attrs.duration_sec,
          requested_duration_sec: nil,
          status: attrs.status,
          audio_url: attrs.audio_url,
          image_url: nil,
          provider: "manual-admin",
          provider_account: "manual-admin",
          output_count: 1,
          tracks: [],
          created_at: now,
          updated_at: now
        }
        |> Store.save()

      {:ok, generation}
    end
  end

  @doc """
  Updates one song from the admin UI.
  """
  @spec update_song(String.t(), map()) :: {:ok, Generation.t()} | {:error, map()} | :not_found
  def update_song(id, params) when is_binary(id) and is_map(params) do
    case get_generation(id) do
      nil ->
        :not_found

      _generation ->
        with {:ok, attrs} <- normalize_song_attrs(params) do
          updated_generation =
            Store.update(id, %{
              user_id: attrs.user_id,
              title: attrs.title,
              prompt: attrs.prompt,
              duration_sec: attrs.duration_sec,
              status: attrs.status,
              audio_url: attrs.audio_url,
              provider: "manual-admin",
              output_count: 1,
              updated_at: now_utc()
            })

          {:ok, updated_generation}
        end
    end
  end

  @doc """
  Deletes one song by id.
  """
  @spec delete_song(String.t()) :: Generation.t() | nil
  def delete_song(id), do: Store.delete(id)

  @doc """
  Returns one generation by id.
  """
  @spec get_generation(String.t()) :: Generation.t() | nil
  def get_generation(id) do
    case Store.get(id) do
      %Generation{provider: "suno-api"} = generation ->
        maybe_refresh_suno_generation(generation)

      nil ->
        restore_generation(id)

      generation ->
        generation
    end
  end

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

  @doc """
  Returns the statuses supported by the admin UI.
  """
  @spec status_options() :: [String.t()]
  def status_options, do: @allowed_statuses

  @doc """
  Processes a Suno callback asynchronously.
  """
  @spec process_suno_callback(map()) :: :ok | {:error, String.t()}
  def process_suno_callback(params) when is_map(params) do
    with {:ok, task_id} <- extract_callback_task_id(params),
         %Generation{} = generation <- Store.get(task_id) || restore_generation(task_id) do
      generation
      |> merge_suno_callback(params)
      |> persist_generation_if_changed(generation)

      :ok
    else
      {:error, message} ->
        {:error, message}

      nil ->
        Logger.warning("Ignored Suno callback for unknown task: #{inspect(params)}")
        :ok
    end
  end

  defp create_suno_generation(prompt, user_id, requested_duration_sec) do
    with {:ok, %{task_id: task_id, account_alias: account_alias}} <-
           SunoClient.generate_music(prompt) do
      generation =
        %Generation{
          id: task_id,
          user_id: user_id,
          title: nil,
          prompt: prompt,
          duration_sec: 0,
          requested_duration_sec: requested_duration_sec,
          status: "processing",
          audio_url: nil,
          image_url: nil,
          provider: "suno-api",
          provider_account: account_alias,
          output_count: 2,
          tracks: [],
          created_at: now_utc(),
          updated_at: now_utc()
        }
        |> persist_generation()

      {:ok,
       %{
         taskId: generation.id,
         status: generation.status,
         outputCount: generation.output_count
       }}
    end
  end

  defp create_mock_generation(prompt, user_id, requested_duration_sec) do
    now = now_utc()
    id = build_id()

    generation =
      %Generation{
        id: id,
        user_id: user_id,
        title: nil,
        prompt: prompt,
        duration_sec: 0,
        requested_duration_sec: requested_duration_sec,
        status: "processing",
        audio_url: nil,
        image_url: nil,
        provider: @default_provider,
        provider_account: "mock-primary",
        output_count: 2,
        tracks: [],
        created_at: now,
        updated_at: now
      }
      |> persist_generation()

    Task.start(fn -> complete_mock_generation(generation) end)

    {:ok,
     %{
       taskId: generation.id,
       status: generation.status,
       outputCount: generation.output_count
     }}
  end

  defp refresh_suno_generation(%Generation{} = generation) do
    case SunoClient.get_generation(generation.id, account_alias: generation.provider_account) do
      {:ok, response} ->
        generation
        |> merge_suno_generation(response)
        |> persist_generation_if_changed(generation)

      {:error, _message} ->
        generation
    end
  end

  defp maybe_refresh_suno_generation(%Generation{} = generation) do
    if should_refresh_suno_generation(generation) do
      refresh_suno_generation(generation)
    else
      generation
    end
  end

  defp should_refresh_suno_generation(%Generation{} = generation) do
    generation.status in @active_suno_statuses and
      stale_generation?(generation, suno_fallback_poll_interval_ms())
  end

  defp complete_mock_generation(generation) do
    tracks = build_mock_tracks(generation)
    [first_track, _second_track] = tracks

    Process.sleep(@processing_delay_ms)

    Store.update(generation.id, %{
      status: "first_success",
      title: first_track.title,
      duration_sec: first_track.duration_sec,
      audio_url: first_track.audio_url,
      image_url: first_track.image_url,
      tracks: [first_track],
      updated_at: now_utc()
    })
    |> sync_generation()

    Process.sleep(@processing_delay_ms)

    Store.update(generation.id, %{
      status: "success",
      title: first_track.title,
      duration_sec: first_track.duration_sec,
      audio_url: first_track.audio_url,
      image_url: first_track.image_url,
      tracks: tracks,
      updated_at: now_utc()
    })
    |> sync_generation()
  end

  defp restore_generation(id) when is_binary(id) do
    case FirestoreClient.restore_generation(id) do
      {:ok, %Generation{} = generation} ->
        generation
        |> Store.save()
        |> then(fn restored_generation ->
          if restored_generation.provider == "suno-api" do
            maybe_refresh_suno_generation(restored_generation)
          else
            restored_generation
          end
        end)

      :not_found ->
        nil

      {:error, message} ->
        Logger.warning("Failed to restore generation #{id} from Firestore: #{message}")
        nil
    end
  end

  defp build_mock_tracks(generation) do
    now = now_utc()
    base_title = build_title(generation.prompt)
    tags = build_tags(generation.prompt)

    Enum.with_index(@demo_audio_urls)
    |> Enum.map(fn {audio_url, index} ->
      suffix = if index == 0, do: "A", else: "B"

      %{
        id: "#{generation.id}_#{String.downcase(suffix)}",
        variant_index: index,
        title: "#{base_title} #{suffix}",
        prompt: generation.prompt,
        duration_sec: 135 + index,
        audio_url: audio_url,
        stream_audio_url: audio_url,
        image_url: build_demo_image_url(generation.id, suffix),
        provider: @default_provider,
        provider_account: generation.provider_account,
        model_name: @default_model,
        tags: tags,
        created_at: now
      }
    end)
  end

  defp build_demo_image_url(generation_id, suffix) do
    "https://picsum.photos/seed/#{generation_id}_#{suffix}/640/640"
  end

  defp merge_suno_generation(%Generation{} = generation, response) when is_map(response) do
    tracks =
      response
      |> build_suno_tracks(generation)
      |> merge_persisted_track_assets(generation.tracks || [])
      |> persist_suno_track_assets()

    first_track = List.first(tracks)
    status = normalize_external_status(response["status"])
    response_track_count = response_track_count(response)

    %Generation{
      generation
      | status: status,
        title: track_value(first_track, :title, generation.title),
        duration_sec: track_value(first_track, :duration_sec, generation.duration_sec),
        audio_url: track_value(first_track, :audio_url, generation.audio_url),
        image_url: track_value(first_track, :image_url, generation.image_url),
        output_count:
          max(max(response_track_count, length(tracks)), generation.output_count || 0),
        tracks: tracks,
        updated_at: generation.updated_at
    }
  end

  defp merge_suno_callback(%Generation{} = generation, params) when is_map(params) do
    callback_data = Map.get(params, "data", %{})
    callback_code = normalize_callback_code(Map.get(params, "code"))
    callback_type = callback_data["callbackType"] || callback_data["callback_type"]

    callback_response = %{
      "status" => callback_status(callback_type, callback_code),
      "response" => %{
        "sunoData" => Map.get(callback_data, "data", [])
      }
    }

    merge_suno_generation(generation, callback_response)
  end

  defp merge_persisted_track_assets(tracks, existing_tracks) when is_list(tracks) do
    existing_by_id =
      existing_tracks
      |> List.wrap()
      |> Map.new(fn track -> {read_track(track, :id), track} end)

    Enum.map(tracks, fn track ->
      case Map.get(existing_by_id, read_track(track, :id)) do
        nil ->
          track

        existing_track ->
          track
          |> maybe_restore_persisted_url(existing_track, :audio_url)
          |> maybe_restore_persisted_url(existing_track, :stream_audio_url)
          |> maybe_restore_persisted_url(existing_track, :image_url)
      end
    end)
  end

  defp persist_suno_track_assets(tracks) when is_list(tracks) do
    Enum.map(tracks, &persist_suno_track_asset/1)
  end

  defp persist_suno_track_asset(track) when is_map(track) do
    persisted_audio_url = persist_track_audio(track)
    persisted_image_url = persist_track_image(track)

    track
    |> Map.put(:audio_url, persisted_audio_url || read_track(track, :audio_url))
    |> Map.put(:stream_audio_url, persisted_audio_url || read_track(track, :stream_audio_url))
    |> Map.put(:image_url, persisted_image_url || read_track(track, :image_url))
  end

  defp persist_track_audio(track) do
    source_url =
      first_present([
        if(CloudinaryClient.cloudinary_url?(read_track(track, :audio_url)),
          do: nil,
          else: read_track(track, :audio_url)
        ),
        if(CloudinaryClient.cloudinary_url?(read_track(track, :stream_audio_url)),
          do: nil,
          else: read_track(track, :stream_audio_url)
        )
      ])

    case CloudinaryClient.persist_remote_asset(
           source_url,
           resource_type: "video",
           default_content_type: "audio/mpeg"
         ) do
      {:ok, url} ->
        url

      {:error, message} ->
        Logger.warning("Cloudinary audio upload failed for #{read_track(track, :id)}: #{message}")
        nil
    end
  end

  defp persist_track_image(track) do
    source_url =
      if CloudinaryClient.cloudinary_url?(read_track(track, :image_url)),
        do: nil,
        else: read_track(track, :image_url)

    case CloudinaryClient.persist_remote_asset(
           source_url,
           resource_type: "image",
           default_content_type: "image/jpeg"
         ) do
      {:ok, url} ->
        url

      {:error, message} ->
        Logger.warning("Cloudinary image upload failed for #{read_track(track, :id)}: #{message}")
        nil
    end
  end

  defp maybe_restore_persisted_url(track, existing_track, field) do
    persisted_url = read_track(existing_track, field)

    if CloudinaryClient.cloudinary_url?(persisted_url) do
      Map.put(track, field, persisted_url)
    else
      track
    end
  end

  defp build_suno_tracks(response, generation) do
    suno_data =
      case Map.get(response, "response") do
        %{} = nested_response -> Map.get(nested_response, "sunoData", [])
        _other -> []
      end

    suno_data
    |> Enum.with_index()
    |> Enum.map(fn {track, index} ->
      create_time =
        track["createTime"] ||
          response["createTime"] ||
          generation.created_at

      %{
        id: external_track_value(track, ["id"]) || "#{generation.id}_#{index}",
        variant_index: index,
        title:
          external_track_value(track, ["title"]) ||
            "#{build_title(generation.prompt)} #{variant_suffix(index)}",
        prompt: external_track_value(track, ["prompt"]) || generation.prompt,
        duration_sec: normalize_duration_value(external_track_value(track, ["duration"])),
        audio_url:
          first_present([
            external_track_value(track, ["sourceAudioUrl", "source_audio_url"]),
            external_track_value(track, ["audioUrl", "audio_url"]),
            external_track_value(track, ["sourceStreamAudioUrl", "source_stream_audio_url"]),
            external_track_value(track, ["streamAudioUrl", "stream_audio_url"])
          ]),
        stream_audio_url:
          first_present([
            external_track_value(track, ["sourceStreamAudioUrl", "source_stream_audio_url"]),
            external_track_value(track, ["streamAudioUrl", "stream_audio_url"]),
            external_track_value(track, ["sourceAudioUrl", "source_audio_url"]),
            external_track_value(track, ["audioUrl", "audio_url"])
          ]),
        image_url:
          first_present([
            external_track_value(track, ["sourceImageUrl", "source_image_url"]),
            external_track_value(track, ["imageUrl", "image_url"])
          ]),
        provider: "suno-api",
        provider_account: generation.provider_account,
        model_name:
          external_track_value(track, ["modelName", "model_name"]) || response["type"] ||
            @default_model,
        tags: build_tags(external_track_value(track, ["tags"]) || generation.prompt),
        created_at: normalize_datetime(create_time)
      }
    end)
  end

  defp extract_callback_task_id(%{"data" => %{} = callback_data}) do
    case callback_data["task_id"] || callback_data["taskId"] do
      task_id when is_binary(task_id) and task_id != "" -> {:ok, task_id}
      _other -> {:error, "Suno callback thiếu task_id"}
    end
  end

  defp extract_callback_task_id(_params), do: {:error, "Suno callback không hợp lệ"}

  defp callback_status(_callback_type, callback_code) when callback_code != 200, do: "failed"

  defp callback_status(callback_type, 200) when is_binary(callback_type) do
    case String.downcase(String.trim(callback_type)) do
      "text" -> "processing"
      "first" -> "first_success"
      "complete" -> "success"
      "error" -> "failed"
      _other -> "processing"
    end
  end

  defp callback_status(_callback_type, _callback_code), do: "processing"

  defp normalize_callback_code(code) when is_integer(code), do: code

  defp normalize_callback_code(code) when is_binary(code) do
    case Integer.parse(code) do
      {parsed_code, ""} -> parsed_code
      _result -> 500
    end
  end

  defp normalize_callback_code(_code), do: 500

  defp normalize_external_status(status) when is_binary(status) do
    case String.upcase(String.trim(status)) do
      "PENDING" -> "processing"
      "TEXT_SUCCESS" -> "processing"
      "FIRST_SUCCESS" -> "first_success"
      "SUCCESS" -> "success"
      "COMPLETED" -> "completed"
      "CREATE_TASK_FAILED" -> "failed"
      "GENERATE_AUDIO_FAILED" -> "failed"
      "CALLBACK_EXCEPTION" -> "failed"
      "SENSITIVE_WORD_ERROR" -> "failed"
      other -> String.downcase(other)
    end
  end

  defp normalize_external_status(_status), do: "processing"

  defp normalize_duration_value(value) when is_integer(value), do: value
  defp normalize_duration_value(value) when is_float(value), do: round(value)

  defp normalize_duration_value(value) when is_binary(value) do
    case Float.parse(value) do
      {parsed, ""} -> round(parsed)
      _result -> 0
    end
  end

  defp normalize_duration_value(_value), do: 0

  defp normalize_datetime(%DateTime{} = value), do: value

  defp normalize_datetime(value) when is_integer(value) do
    DateTime.from_unix!(value, :millisecond) |> DateTime.truncate(:second)
  end

  defp normalize_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        DateTime.truncate(datetime, :second)

      _error ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive_datetime} ->
            naive_datetime
            |> DateTime.from_naive!("Etc/UTC")
            |> DateTime.truncate(:second)

          _second_error ->
            now_utc()
        end
    end
  end

  defp normalize_datetime(_value), do: now_utc()

  defp track_value(nil, _field, fallback), do: fallback
  defp track_value(track, field, fallback), do: Map.get(track, field, fallback)

  defp read_track(track, field) when is_map(track) do
    Map.get(track, field) || Map.get(track, Atom.to_string(field))
  end

  defp external_track_value(track, keys) when is_map(track) and is_list(keys) do
    Enum.find_value(keys, fn key ->
      case Map.get(track, key) do
        value when is_binary(value) -> if String.trim(value) == "", do: nil, else: value
        nil -> nil
        value -> value
      end
    end)
  end

  defp first_present(values) when is_list(values) do
    Enum.find(values, fn
      value when is_binary(value) -> String.trim(value) != ""
      nil -> false
      _other -> true
    end)
  end

  defp response_track_count(%{"response" => %{} = response}) do
    response
    |> Map.get("sunoData", [])
    |> length()
  end

  defp response_track_count(_response), do: 0

  defp generation_changed?(%Generation{} = current, %Generation{} = next) do
    generation_signature(current) != generation_signature(next)
  end

  defp persist_generation_if_changed(%Generation{} = next, %Generation{} = current) do
    if generation_changed?(current, next) do
      next
      |> Map.put(:updated_at, now_utc())
      |> persist_generation()
    else
      current
    end
  end

  defp generation_signature(%Generation{} = generation) do
    %{
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
      output_count: generation.output_count,
      tracks: Enum.map(List.wrap(generation.tracks), &track_signature/1)
    }
  end

  defp track_signature(track) when is_map(track) do
    %{
      id: read_track(track, :id),
      variant_index: read_track(track, :variant_index),
      title: read_track(track, :title),
      prompt: read_track(track, :prompt),
      duration_sec: read_track(track, :duration_sec),
      audio_url: read_track(track, :audio_url),
      stream_audio_url: read_track(track, :stream_audio_url),
      image_url: read_track(track, :image_url),
      provider: read_track(track, :provider),
      provider_account: read_track(track, :provider_account),
      model_name: read_track(track, :model_name),
      tags: read_track(track, :tags),
      created_at: read_track(track, :created_at)
    }
  end

  defp stale_generation?(%Generation{updated_at: %DateTime{} = updated_at}, threshold_ms)
       when is_integer(threshold_ms) and threshold_ms >= 0 do
    DateTime.diff(now_utc(), updated_at, :millisecond) >= threshold_ms
  end

  defp stale_generation?(_generation, _threshold_ms), do: true

  defp variant_suffix(index) when index <= 0, do: "A"
  defp variant_suffix(1), do: "B"
  defp variant_suffix(index), do: Integer.to_string(index + 1)

  defp build_tags(prompt) do
    prompt
    |> normalize_tag_source()
    |> Enum.take(6)
  end

  defp normalize_tag_source(value) when is_binary(value) do
    value
    |> String.split(~r/[,]/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_tag_source(value) when is_list(value) do
    value
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_tag_source(_value), do: []

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

  defp normalize_requested_duration(nil), do: nil

  defp normalize_requested_duration(duration_sec) when is_integer(duration_sec) do
    if duration_sec in 1..60, do: duration_sec, else: nil
  end

  defp normalize_requested_duration(duration_sec) when is_binary(duration_sec) do
    case Integer.parse(duration_sec) do
      {parsed_duration, ""} -> normalize_requested_duration(parsed_duration)
      _result -> nil
    end
  end

  defp normalize_requested_duration(_duration_sec), do: nil

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

  defp normalize_song_attrs(params) do
    user_id = normalize_required_user_id(Map.get(params, "user_id") || Map.get(params, :user_id))
    prompt = normalize_prompt(Map.get(params, "prompt") || Map.get(params, :prompt))
    title = normalize_title(Map.get(params, "title") || Map.get(params, :title), prompt)

    duration_sec =
      normalize_duration(Map.get(params, "duration_sec") || Map.get(params, :duration_sec))

    status =
      normalize_status(Map.get(params, "status") || Map.get(params, :status))

    audio_url =
      normalize_optional_text(Map.get(params, "audio_url") || Map.get(params, :audio_url))

    errors =
      %{}
      |> put_error(:user_id, user_id == nil, "user_id is required")
      |> put_error(:prompt, prompt == nil, "prompt must not be empty")
      |> put_error(:status, status == nil, "status is invalid")

    case errors do
      %{} = map when map_size(map) == 0 ->
        {:ok,
         %{
           user_id: user_id,
           title: title,
           prompt: prompt,
           duration_sec: duration_sec,
           status: status,
           audio_url: audio_url
         }}

      _map ->
        {:error, errors}
    end
  end

  defp normalize_required_user_id(user_id) when is_binary(user_id) do
    user_id
    |> String.trim()
    |> case do
      "" -> nil
      cleaned_user_id -> cleaned_user_id
    end
  end

  defp normalize_required_user_id(_user_id), do: nil

  defp normalize_prompt(prompt) when is_binary(prompt) do
    prompt
    |> String.trim()
    |> case do
      "" -> nil
      cleaned_prompt -> cleaned_prompt
    end
  end

  defp normalize_prompt(_prompt), do: nil

  defp normalize_title(title, prompt) when is_binary(title) do
    title
    |> String.trim()
    |> case do
      "" -> default_title(prompt)
      cleaned_title -> cleaned_title
    end
  end

  defp normalize_title(_title, prompt), do: default_title(prompt)

  defp default_title(prompt) when is_binary(prompt), do: build_title(prompt)
  defp default_title(_prompt), do: "AI - Untitled"

  defp normalize_status(status) when is_binary(status) do
    cleaned_status = String.trim(status)
    if cleaned_status in @allowed_statuses, do: cleaned_status, else: nil
  end

  defp normalize_status(_status), do: nil

  defp normalize_optional_text(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      cleaned_value -> cleaned_value
    end
  end

  defp normalize_optional_text(_value), do: nil

  defp put_error(errors, _field, false, _message), do: errors
  defp put_error(errors, field, true, message), do: Map.put(errors, field, message)

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

  defp now_utc do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
  end

  defp suno_fallback_poll_interval_ms do
    Application.get_env(:backend, :suno, [])
    |> Keyword.get(:fallback_poll_interval_ms, 10_000)
  end

  defp persist_generation(%Generation{} = generation) do
    generation
    |> Store.save()
    |> tap(&sync_generation/1)
  end

  defp sync_generation(nil), do: :ok

  defp sync_generation(%Generation{} = generation) do
    case FirestoreClient.upsert_generation(generation) do
      :ok ->
        :ok

      {:error, message} ->
        Logger.warning("Firestore sync skipped for #{generation.id}: #{message}")
        :ok
    end
  end
end
