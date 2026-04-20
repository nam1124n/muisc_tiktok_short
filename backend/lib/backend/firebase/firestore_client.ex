defmodule Backend.Firebase.FirestoreClient do
  @moduledoc """
  Best-effort Firestore sync for generated Suno tasks.
  """

  alias Backend.Firebase.TokenCache
  alias Backend.Music.Generation

  @identity_toolkit_url "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
  @firestore_base_url "https://firestore.googleapis.com/v1"
  @request_timeout_ms 45_000
  @firestore_page_size 200

  @spec enabled?() :: boolean()
  def enabled? do
    config()[:enabled] == true and
      config()[:project_id] not in [nil, ""] and
      config()[:web_api_key] not in [nil, ""] and
      config()[:email] not in [nil, ""] and
      config()[:password] not in [nil, ""]
  end

  @spec upsert_generation(Generation.t()) :: :ok | {:error, String.t()}
  def upsert_generation(%Generation{} = generation) do
    if enabled?() do
      do_upsert_generation(generation)
    else
      :ok
    end
  end

  @spec restore_generation(String.t()) ::
          {:ok, Generation.t()} | :not_found | {:error, String.t()}
  def restore_generation(task_id) when is_binary(task_id) and task_id != "" do
    if enabled?() do
      with {:ok, id_token} <- fetch_id_token() do
        case fetch_document(task_index_path(task_id), id_token) do
          {:ok, %{"fields" => fields}} when is_map(fields) ->
            {:ok, fields |> decode_fields() |> build_generation_from_index()}

          {:ok, _document} ->
            {:error, "Firestore task index không hợp lệ"}

          :not_found ->
            :not_found

          {:error, message} ->
            {:error, message}
        end
      end
    else
      :not_found
    end
  end

  @spec list_generations() :: {:ok, [Generation.t()]} | {:error, String.t()}
  def list_generations do
    if enabled?() do
      with {:ok, id_token} <- fetch_id_token(),
           {:ok, documents} <-
             fetch_collection_documents(generation_index_collection_path(), id_token) do
        {:ok,
         documents
         |> Enum.map(&build_generation_from_index_document/1)
         |> sort_generations()}
      end
    else
      {:ok, []}
    end
  end

  @spec list_generations_by_user(String.t()) :: {:ok, [Generation.t()]} | {:error, String.t()}
  def list_generations_by_user(user_id) when is_binary(user_id) and user_id != "" do
    if enabled?() do
      with {:ok, id_token} <- fetch_id_token(),
           {:ok, task_documents} <-
             fetch_collection_documents(task_collection_path(user_id), id_token),
           {:ok, track_documents} <-
             fetch_collection_documents(track_collection_path(user_id), id_token) do
        tracks_by_task_id =
          track_documents
          |> Enum.map(&decode_document_fields/1)
          |> Enum.group_by(&Map.get(&1, "taskId"))

        {:ok,
         task_documents
         |> Enum.map(fn document ->
           document
           |> decode_document_fields()
           |> build_generation_from_task_document(tracks_by_task_id)
         end)
         |> sort_generations()}
      end
    else
      {:ok, []}
    end
  end

  def list_generations_by_user(_user_id), do: {:ok, []}

  @spec delete_generation(Generation.t()) :: :ok | {:error, String.t()}
  def delete_generation(%Generation{} = generation) do
    if enabled?() do
      with {:ok, id_token} <- fetch_id_token(),
           {:ok, _response} <- commit_writes(build_delete_writes(generation), id_token) do
        :ok
      end
    else
      :ok
    end
  end

  defp do_upsert_generation(%Generation{} = generation) do
    with {:ok, id_token} <- fetch_id_token(),
         {:ok, _response} <- commit_writes(build_writes(generation), id_token) do
      :ok
    end
  end

  defp build_writes(%Generation{} = generation) do
    task_fields =
      %{
        "taskId" => generation.id,
        "userId" => generation.user_id,
        "prompt" => generation.prompt,
        "status" => generation.status,
        "provider" => generation.provider,
        "providerAccount" => generation.provider_account,
        "keyAlias" => generation.provider_account,
        "title" => generation.title,
        "durationSeconds" => generation.duration_sec,
        "audioUrl" => generation.audio_url,
        "imageUrl" => generation.image_url,
        "outputCount" => generation.output_count || length(generation.tracks || []),
        "createdAt" => generation.created_at,
        "updatedAt" => generation.updated_at
      }
      |> maybe_put("requestedDurationSeconds", generation.requested_duration_sec)

    task_write =
      build_update_write(
        document_name(task_path(generation.user_id, generation.id)),
        task_fields
      )

    track_writes =
      generation.tracks
      |> List.wrap()
      |> Enum.map(fn track ->
        track_fields = %{
          "id" => read_track(track, :id),
          "taskId" => generation.id,
          "userId" => generation.user_id,
          "variantIndex" => read_track(track, :variant_index) || 0,
          "title" => read_track(track, :title),
          "prompt" => read_track(track, :prompt) || generation.prompt,
          "audioUrl" => read_track(track, :audio_url),
          "streamAudioUrl" =>
            read_track(track, :stream_audio_url) || read_track(track, :audio_url),
          "imageUrl" => read_track(track, :image_url),
          "durationSeconds" => read_track(track, :duration_sec) || 0,
          "provider" => read_track(track, :provider) || generation.provider,
          "providerAccount" =>
            read_track(track, :provider_account) || generation.provider_account,
          "keyAlias" => read_track(track, :provider_account) || generation.provider_account,
          "modelName" => read_track(track, :model_name),
          "tags" => read_track(track, :tags) || [],
          "createdAt" => read_track(track, :created_at) || generation.created_at
        }

        build_update_write(
          document_name(track_path(generation.user_id, read_track(track, :id))),
          track_fields
        )
      end)

    task_index_write =
      build_update_write(
        document_name(task_index_path(generation.id)),
        build_task_index_fields(generation)
      )

    [task_write | track_writes] ++ [task_index_write]
  end

  defp build_task_index_fields(%Generation{} = generation) do
    %{
      "taskId" => generation.id,
      "userId" => generation.user_id,
      "prompt" => generation.prompt,
      "status" => generation.status,
      "provider" => generation.provider,
      "providerAccount" => generation.provider_account,
      "keyAlias" => generation.provider_account,
      "title" => generation.title,
      "durationSeconds" => generation.duration_sec,
      "requestedDurationSeconds" => generation.requested_duration_sec,
      "audioUrl" => generation.audio_url,
      "imageUrl" => generation.image_url,
      "outputCount" => generation.output_count || length(generation.tracks || []),
      "tracks" =>
        generation.tracks
        |> List.wrap()
        |> Enum.map(fn track ->
          %{
            "id" => read_track(track, :id),
            "variantIndex" => read_track(track, :variant_index) || 0,
            "title" => read_track(track, :title),
            "prompt" => read_track(track, :prompt) || generation.prompt,
            "durationSeconds" => read_track(track, :duration_sec) || 0,
            "audioUrl" => read_track(track, :audio_url),
            "streamAudioUrl" =>
              read_track(track, :stream_audio_url) || read_track(track, :audio_url),
            "imageUrl" => read_track(track, :image_url),
            "provider" => read_track(track, :provider) || generation.provider,
            "providerAccount" =>
              read_track(track, :provider_account) || generation.provider_account,
            "keyAlias" => read_track(track, :provider_account) || generation.provider_account,
            "modelName" => read_track(track, :model_name),
            "tags" => read_track(track, :tags) || [],
            "createdAt" => read_track(track, :created_at) || generation.created_at
          }
        end),
      "createdAt" => generation.created_at,
      "updatedAt" => generation.updated_at
    }
  end

  defp build_update_write(document_name, fields) do
    cleaned_fields =
      fields
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    %{
      "update" => %{
        "name" => document_name,
        "fields" => encode_fields(cleaned_fields)
      },
      "updateMask" => %{
        "fieldPaths" => Map.keys(cleaned_fields)
      }
    }
  end

  defp build_delete_writes(%Generation{} = generation) do
    track_deletes =
      generation.tracks
      |> List.wrap()
      |> Enum.flat_map(fn track ->
        case read_track(track, :id) do
          track_id when is_binary(track_id) and track_id != "" ->
            [build_delete_write(document_name(track_path(generation.user_id, track_id)))]

          _other ->
            []
        end
      end)

    [
      build_delete_write(document_name(task_path(generation.user_id, generation.id)))
      | track_deletes
    ] ++ [build_delete_write(document_name(task_index_path(generation.id)))]
  end

  defp build_delete_write(document_name) do
    %{"delete" => document_name}
  end

  defp commit_writes(writes, id_token) when is_list(writes) do
    ensure_http_stack_started()
    body = Jason.encode!(%{"writes" => writes})

    case :httpc.request(
           :post,
           {commit_url(), request_headers(id_token), ~c"application/json", body},
           http_options(),
           request_options()
         ) do
      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}}
      when status_code in 200..299 ->
        decode_json(response_body)

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}} ->
        with {:ok, decoded} <- decode_json(response_body) do
          {:error, decode_error_message(decoded, "Firestore sync thất bại (HTTP #{status_code})")}
        else
          _error -> {:error, "Firestore sync thất bại (HTTP #{status_code})"}
        end

      {:error, reason} ->
        {:error, "Không thể ghi Firestore: #{format_reason(reason)}"}
    end
  end

  defp fetch_id_token do
    case TokenCache.get_valid_token() do
      token when is_binary(token) and token != "" ->
        {:ok, token}

      _other ->
        sign_in_with_password()
    end
  end

  defp sign_in_with_password do
    ensure_http_stack_started()

    body =
      Jason.encode!(%{
        email: config()[:email],
        password: config()[:password],
        returnSecureToken: true
      })

    case :httpc.request(
           :post,
           {identity_toolkit_url(), request_headers(nil), ~c"application/json", body},
           http_options(),
           request_options()
         ) do
      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}}
      when status_code in 200..299 ->
        with {:ok, decoded} <- decode_json(response_body),
             id_token when is_binary(id_token) and id_token != "" <- decoded["idToken"],
             expires_in when is_binary(expires_in) <- decoded["expiresIn"],
             {expires_in_seconds, ""} <- Integer.parse(expires_in) do
          TokenCache.put_token(id_token, expires_in_seconds)
          {:ok, id_token}
        else
          _unexpected -> {:error, "Firebase Auth không trả về idToken hợp lệ"}
        end

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}} ->
        with {:ok, decoded} <- decode_json(response_body) do
          {:error, decode_error_message(decoded, "Firebase Auth thất bại (HTTP #{status_code})")}
        else
          _error -> {:error, "Firebase Auth thất bại (HTTP #{status_code})"}
        end

      {:error, reason} ->
        {:error, "Không thể xác thực Firebase: #{format_reason(reason)}"}
    end
  end

  defp commit_url do
    "#{@firestore_base_url}/projects/#{config()[:project_id]}/databases/(default)/documents:commit"
    |> String.to_charlist()
  end

  defp identity_toolkit_url do
    "#{@identity_toolkit_url}?key=#{config()[:web_api_key]}"
    |> String.to_charlist()
  end

  defp request_headers(nil), do: [{~c"Content-Type", ~c"application/json"}]

  defp request_headers(id_token) do
    [
      {~c"Authorization", "Bearer #{id_token}" |> String.to_charlist()},
      {~c"Content-Type", ~c"application/json"}
    ]
  end

  defp http_options do
    [timeout: @request_timeout_ms, connect_timeout: 15_000]
  end

  defp request_options do
    [body_format: :binary]
  end

  defp document_name(document_path) do
    "projects/#{config()[:project_id]}/databases/(default)/documents/#{document_path}"
  end

  defp task_path(user_id, task_id) do
    "users/#{user_id}/generation_tasks/#{task_id}"
  end

  defp task_collection_path(user_id) do
    "users/#{user_id}/generation_tasks"
  end

  defp track_path(user_id, track_id) do
    "users/#{user_id}/generated_tracks/#{track_id}"
  end

  defp track_collection_path(user_id) do
    "users/#{user_id}/generated_tracks"
  end

  defp task_index_path(task_id) do
    "generation_task_index/#{task_id}"
  end

  defp generation_index_collection_path do
    "generation_task_index"
  end

  defp encode_fields(fields) when is_map(fields) do
    Map.new(fields, fn {key, value} -> {key, encode_value(value)} end)
  end

  defp encode_value(%DateTime{} = value) do
    %{"timestampValue" => DateTime.to_iso8601(value)}
  end

  defp encode_value(value) when is_boolean(value) do
    %{"booleanValue" => value}
  end

  defp encode_value(value) when is_integer(value) do
    %{"integerValue" => Integer.to_string(value)}
  end

  defp encode_value(value) when is_float(value) do
    %{"doubleValue" => value}
  end

  defp encode_value(value) when is_binary(value) do
    %{"stringValue" => value}
  end

  defp encode_value(value) when is_list(value) do
    encoded_values =
      value
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&encode_value/1)

    %{"arrayValue" => maybe_put(%{}, "values", encoded_values)}
  end

  defp encode_value(value) when is_map(value) do
    %{"mapValue" => %{"fields" => encode_fields(value)}}
  end

  defp encode_value(nil) do
    %{"nullValue" => nil}
  end

  defp encode_value(value) do
    %{"stringValue" => to_string(value)}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp read_track(track, key) when is_map(track) do
    Map.get(track, key) || Map.get(track, Atom.to_string(key))
  end

  defp read_track(_track, _key), do: nil

  defp fetch_document(document_path, id_token) do
    ensure_http_stack_started()

    case :httpc.request(
           :get,
           {document_url(document_path), request_headers(id_token)},
           http_options(),
           request_options()
         ) do
      {:ok, {{_http_version, 404, _reason_phrase}, _headers, _body}} ->
        :not_found

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}}
      when status_code in 200..299 ->
        decode_json(response_body)

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}} ->
        with {:ok, decoded} <- decode_json(response_body) do
          {:error, decode_error_message(decoded, "Firestore read thất bại (HTTP #{status_code})")}
        else
          _error -> {:error, "Firestore read thất bại (HTTP #{status_code})"}
        end

      {:error, reason} ->
        {:error, "Không thể đọc Firestore: #{format_reason(reason)}"}
    end
  end

  defp fetch_collection_documents(collection_path, id_token) do
    do_fetch_collection_documents(collection_path, id_token, nil, [])
  end

  defp do_fetch_collection_documents(collection_path, id_token, page_token, documents) do
    case fetch_collection(collection_path, id_token, page_token: page_token) do
      {:ok, %{"documents" => response_documents} = response} when is_list(response_documents) ->
        next_documents = documents ++ response_documents

        case Map.get(response, "nextPageToken") do
          next_page_token when is_binary(next_page_token) and next_page_token != "" ->
            do_fetch_collection_documents(
              collection_path,
              id_token,
              next_page_token,
              next_documents
            )

          _other ->
            {:ok, next_documents}
        end

      {:ok, %{"nextPageToken" => next_page_token}}
      when is_binary(next_page_token) and next_page_token != "" ->
        do_fetch_collection_documents(collection_path, id_token, next_page_token, documents)

      {:ok, _response} ->
        {:ok, documents}

      {:error, message} ->
        {:error, message}
    end
  end

  defp fetch_collection(collection_path, id_token, opts) do
    ensure_http_stack_started()

    case :httpc.request(
           :get,
           {collection_url(collection_path, opts), request_headers(id_token)},
           http_options(),
           request_options()
         ) do
      {:ok, {{_http_version, 404, _reason_phrase}, _headers, _body}} ->
        {:ok, %{}}

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}}
      when status_code in 200..299 ->
        decode_json(response_body)

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}} ->
        with {:ok, decoded} <- decode_json(response_body) do
          {:error, decode_error_message(decoded, "Firestore list thất bại (HTTP #{status_code})")}
        else
          _error -> {:error, "Firestore list thất bại (HTTP #{status_code})"}
        end

      {:error, reason} ->
        {:error, "Không thể đọc danh sách Firestore: #{format_reason(reason)}"}
    end
  end

  defp document_url(document_path) do
    "#{@firestore_base_url}/projects/#{config()[:project_id]}/databases/(default)/documents/#{document_path}"
    |> String.to_charlist()
  end

  defp collection_url(collection_path, opts) do
    query =
      %{}
      |> maybe_put("pageSize", Keyword.get(opts, :page_size, @firestore_page_size))
      |> maybe_put("pageToken", Keyword.get(opts, :page_token))
      |> URI.encode_query()

    "#{@firestore_base_url}/projects/#{config()[:project_id]}/databases/(default)/documents/#{collection_path}"
    |> then(fn base_url ->
      if query == "" do
        base_url
      else
        "#{base_url}?#{query}"
      end
    end)
    |> String.to_charlist()
  end

  defp decode_document_fields(%{"fields" => fields}) when is_map(fields),
    do: decode_fields(fields)

  defp decode_document_fields(_document), do: %{}

  defp build_generation_from_index_document(document) do
    document
    |> decode_document_fields()
    |> build_generation_from_index()
  end

  defp decode_fields(fields) when is_map(fields) do
    Map.new(fields, fn {key, value} -> {key, decode_value(value)} end)
  end

  defp decode_value(%{"timestampValue" => value}) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _error -> value
    end
  end

  defp decode_value(%{"stringValue" => value}), do: value
  defp decode_value(%{"booleanValue" => value}), do: value

  defp decode_value(%{"integerValue" => value}) when is_binary(value),
    do: String.to_integer(value)

  defp decode_value(%{"doubleValue" => value}) when is_number(value), do: value
  defp decode_value(%{"doubleValue" => value}) when is_binary(value), do: String.to_float(value)
  defp decode_value(%{"nullValue" => _value}), do: nil

  defp decode_value(%{"mapValue" => %{"fields" => fields}}) when is_map(fields) do
    decode_fields(fields)
  end

  defp decode_value(%{"arrayValue" => %{} = array_value}) do
    array_value
    |> Map.get("values", [])
    |> Enum.map(&decode_value/1)
  end

  defp decode_value(value), do: value

  defp build_generation_from_index(index_data) when is_map(index_data) do
    %Generation{
      id: index_data["taskId"] || "",
      user_id: index_data["userId"] || "guest_user",
      title: index_data["title"],
      prompt: index_data["prompt"] || "",
      duration_sec: normalize_integer(index_data["durationSeconds"]),
      requested_duration_sec: normalize_optional_integer(index_data["requestedDurationSeconds"]),
      status: index_data["status"] || "processing",
      audio_url: index_data["audioUrl"],
      image_url: index_data["imageUrl"],
      provider: index_data["provider"],
      provider_account: index_data["providerAccount"] || index_data["keyAlias"],
      output_count: normalize_optional_integer(index_data["outputCount"]),
      tracks:
        index_data
        |> Map.get("tracks", [])
        |> Enum.map(&build_track_from_index/1)
        |> Enum.sort_by(&read_track(&1, :variant_index)),
      created_at: normalize_datetime(index_data["createdAt"]),
      updated_at: normalize_datetime(index_data["updatedAt"])
    }
  end

  defp build_generation_from_task_document(task_data, tracks_by_task_id) when is_map(task_data) do
    task_id = task_data["taskId"] || ""

    tracks =
      tracks_by_task_id
      |> Map.get(task_id, [])
      |> Enum.map(&build_track_from_index/1)
      |> Enum.sort_by(&read_track(&1, :variant_index))

    first_track = List.first(tracks)

    %Generation{
      id: task_id,
      user_id: task_data["userId"] || "guest_user",
      title: task_data["title"] || read_track(first_track, :title),
      prompt: task_data["prompt"] || "",
      duration_sec:
        normalize_integer(task_data["durationSeconds"] || read_track(first_track, :duration_sec)),
      requested_duration_sec: normalize_optional_integer(task_data["requestedDurationSeconds"]),
      status: task_data["status"] || "processing",
      audio_url: task_data["audioUrl"] || read_track(first_track, :audio_url),
      image_url: task_data["imageUrl"] || read_track(first_track, :image_url),
      provider: task_data["provider"],
      provider_account: task_data["providerAccount"] || task_data["keyAlias"],
      output_count: normalize_optional_integer(task_data["outputCount"]) || length(tracks),
      tracks: tracks,
      created_at: normalize_datetime(task_data["createdAt"]),
      updated_at: normalize_datetime(task_data["updatedAt"])
    }
  end

  defp build_track_from_index(track) when is_map(track) do
    %{
      id: track["id"],
      variant_index: normalize_integer(track["variantIndex"]),
      title: track["title"],
      prompt: track["prompt"],
      duration_sec: normalize_integer(track["durationSeconds"]),
      audio_url: track["audioUrl"],
      stream_audio_url: track["streamAudioUrl"],
      image_url: track["imageUrl"],
      provider: track["provider"],
      provider_account: track["providerAccount"] || track["keyAlias"],
      model_name: track["modelName"],
      tags: List.wrap(track["tags"]),
      created_at: normalize_datetime(track["createdAt"])
    }
  end

  defp normalize_integer(value) when is_integer(value), do: value
  defp normalize_integer(value) when is_float(value), do: round(value)

  defp normalize_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _error -> 0
    end
  end

  defp normalize_integer(_value), do: 0

  defp normalize_optional_integer(nil), do: nil
  defp normalize_optional_integer(value), do: normalize_integer(value)

  defp normalize_datetime(%DateTime{} = value), do: value

  defp normalize_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _error -> DateTime.utc_now() |> DateTime.truncate(:second)
    end
  end

  defp normalize_datetime(_value), do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp sort_generations(generations) do
    Enum.sort(generations, fn left, right ->
      left_timestamp = left.updated_at || left.created_at
      right_timestamp = right.updated_at || right.created_at

      DateTime.compare(left_timestamp, right_timestamp) != :lt
    end)
  end

  defp decode_json(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
      _error -> {:error, "Firestore trả về JSON không hợp lệ"}
    end
  end

  defp decode_error_message(%{"error" => %{"message" => message}}, _fallback)
       when is_binary(message) and message != "" do
    message
  end

  defp decode_error_message(_response, fallback), do: fallback

  defp ensure_http_stack_started do
    _ = Application.ensure_all_started(:inets)
    _ = Application.ensure_all_started(:ssl)
    :ok
  end

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(reason), do: inspect(reason)

  defp config do
    Application.get_env(:backend, :firestore_sync, [])
  end
end
