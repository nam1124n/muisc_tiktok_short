defmodule Backend.Music.Store do
  @moduledoc """
  In-memory store for generated songs.

  This Agent keeps the code simple for the first project phase.
  Later you can replace these functions with Firestore or Ecto queries.
  """

  use Agent

  alias Backend.Music.Generation

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Saves a new song or replaces the existing record with the same id.
  """
  @spec save(Generation.t()) :: Generation.t()
  def save(%Generation{id: id} = generation) do
    Agent.update(__MODULE__, fn state -> Map.put(state, id, generation) end)
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
          {updated_generation, Map.put(state, id, updated_generation)}
      end
    end)
  end
end
