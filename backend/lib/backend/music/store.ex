defmodule Backend.Music.Store do
  @moduledoc """
  Local store for generated songs.

  The Agent keeps an in-memory map for fast reads and also persists it to a
  small JSON file so generated songs survive backend restarts in dev.
  """

  use Agent
  require Logger

  alias Backend.Music.Generation

  def start_link(_opts) do
    Agent.start_link(fn -> load_state() end, name: __MODULE__)
  end

  @doc """
  Saves a new song or replaces the existing record with the same id.
  """
  @spec save(Generation.t()) :: Generation.t()
  def save(%Generation{id: id} = generation) do
    Agent.update(__MODULE__, fn state ->
      next_state = Map.put(state, id, generation)
      persist_state(next_state)
      next_state
    end)

    generation
  end

  @doc """
  Returns one song by id.
  """
  @spec get(String.t()) :: Generation.t() | nil
  def get(id) do
    Agent.get(__MODULE__, fn state -> Map.get(state, id) end)
  end

  @doc """
  Returns all songs ordered by newest first.
  """
  @spec list_all() :: [Generation.t()]
  def list_all do
    __MODULE__
    |> Agent.get(&Map.values/1)
    |> Enum.sort(fn left, right ->
      DateTime.compare(left.created_at, right.created_at) == :gt
    end)
  end

  @doc """
  Returns songs that belong to one user.
  """
  @spec list_by_user(String.t()) :: [Generation.t()]
  def list_by_user(user_id) do
    list_all()
    |> Enum.filter(&(&1.user_id == user_id))
  end

  @doc """
  Updates one song with a partial map of fields.
  """
  @spec update(String.t(), map()) :: Generation.t() | nil
  def update(id, attrs) when is_map(attrs) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Map.get(state, id) do
        nil ->
          {nil, state}

        generation ->
          updated_generation = struct(generation, attrs)
          next_state = Map.put(state, id, updated_generation)
          persist_state(next_state)
          {updated_generation, next_state}
      end
    end)
  end

  @doc """
  Deletes one song by id and returns the deleted record.
  """
  @spec delete(String.t()) :: Generation.t() | nil
  def delete(id) do
    Agent.get_and_update(__MODULE__, fn state ->
      {deleted_generation, next_state} = Map.pop(state, id)
      persist_state(next_state)
      {deleted_generation, next_state}
    end)
  end

  @doc false
  @spec clear() :: :ok
  def clear do
    Agent.update(__MODULE__, fn _state ->
      persist_state(%{})
      %{}
    end)
  end

  defp load_state do
    case File.read(store_path()) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, decoded} when is_map(decoded) ->
            decoded
            |> Enum.map(fn {id, generation_map} ->
              {id, deserialize_generation(generation_map)}
            end)
            |> Map.new()

          {:ok, _decoded} ->
            %{}

          {:error, reason} ->
            Logger.warning("Could not decode persisted generation store: #{inspect(reason)}")
            %{}
        end

      {:error, :enoent} ->
        %{}

      {:error, reason} ->
        Logger.warning("Could not read persisted generation store: #{inspect(reason)}")
        %{}
    end
  end

  defp persist_state(state) when is_map(state) do
    serialized_state =
      state
      |> Enum.map(fn {id, generation} -> {id, serialize_generation(generation)} end)
      |> Map.new()

    case Jason.encode(serialized_state) do
      {:ok, body} ->
        case File.write(store_path(), body) do
          :ok ->
            :ok

          {:error, reason} ->
            Logger.warning("Could not persist generation store: #{inspect(reason)}")
        end

      {:error, reason} ->
        Logger.warning("Could not encode generation store: #{inspect(reason)}")
    end
  end

  defp serialize_generation(%Generation{} = generation) do
    Generation.to_map(generation)
  end

  defp deserialize_generation(generation_map) when is_map(generation_map) do
    %Generation{
      id: read_string(generation_map, "id"),
      user_id: read_string(generation_map, "user_id", fallback: "guest_user"),
      title: read_optional_string(generation_map, "title"),
      prompt: read_string(generation_map, "prompt"),
      duration_sec: read_integer(generation_map, "duration_sec"),
      requested_duration_sec: read_optional_integer(generation_map, "requested_duration_sec"),
      status: read_string(generation_map, "status", fallback: "processing"),
      audio_url: read_optional_string(generation_map, "audio_url"),
      image_url: read_optional_string(generation_map, "image_url"),
      provider: read_optional_string(generation_map, "provider"),
      provider_account: read_optional_string(generation_map, "provider_account"),
      output_count: read_optional_integer(generation_map, "output_count"),
      tracks:
        generation_map
        |> Map.get("tracks", [])
        |> List.wrap()
        |> Enum.map(&deserialize_track/1),
      created_at: read_datetime(generation_map, "created_at"),
      updated_at: read_datetime(generation_map, "updated_at")
    }
  end

  defp deserialize_track(track_map) when is_map(track_map) do
    %{
      id: read_string(track_map, "id"),
      variant_index: read_integer(track_map, "variant_index"),
      title: read_optional_string(track_map, "title"),
      prompt: read_string(track_map, "prompt"),
      duration_sec: read_integer(track_map, "duration_sec"),
      audio_url: read_optional_string(track_map, "audio_url"),
      stream_audio_url: read_optional_string(track_map, "stream_audio_url"),
      image_url: read_optional_string(track_map, "image_url"),
      provider: read_optional_string(track_map, "provider"),
      provider_account: read_optional_string(track_map, "provider_account"),
      model_name: read_optional_string(track_map, "model_name"),
      tags: read_string_list(track_map, "tags"),
      created_at: read_datetime(track_map, "created_at")
    }
  end

  defp deserialize_track(_track_map), do: %{}

  defp read_string(map, key, opts \\ []) do
    fallback = Keyword.get(opts, :fallback, "")

    case Map.get(map, key) do
      value when is_binary(value) -> value
      nil -> fallback
      value -> to_string(value)
    end
  end

  defp read_optional_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" -> value
      _other -> nil
    end
  end

  defp read_integer(map, key) do
    case Map.get(map, key) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        round(value)

      value when is_binary(value) ->
        case Integer.parse(value) do
          {parsed, ""} -> parsed
          _error -> 0
        end

      _other ->
        0
    end
  end

  defp read_optional_integer(map, key) do
    case Map.get(map, key) do
      nil -> nil
      value -> read_integer(%{key => value}, key)
    end
  end

  defp read_string_list(map, key) do
    case Map.get(map, key) do
      value when is_list(value) ->
        value
        |> Enum.map(&to_string/1)
        |> Enum.reject(&(&1 == ""))

      _other ->
        []
    end
  end

  defp read_datetime(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> datetime
          _error -> DateTime.utc_now() |> DateTime.truncate(:second)
        end

      %DateTime{} = value ->
        value

      _other ->
        DateTime.utc_now() |> DateTime.truncate(:second)
    end
  end

  defp store_path do
    Application.get_env(
      :backend,
      :music_store_path,
      Path.join(System.tmp_dir!(), "backend_generation_store.json")
    )
  end
end
