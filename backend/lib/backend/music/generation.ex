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
    :status,
    :audio_url,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          user_id: String.t(),
          title: String.t() | nil,
          prompt: String.t(),
          duration_sec: integer(),
          status: String.t(),
          audio_url: String.t() | nil,
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc """
  Converts the struct into a plain map for JSON responses and templates.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = generation) do
    %{
      id: generation.id,
      user_id: generation.user_id,
      title: generation.title,
      prompt: generation.prompt,
      duration_sec: generation.duration_sec,
      status: generation.status,
      audio_url: generation.audio_url,
      created_at: format_datetime(generation.created_at),
      updated_at: format_datetime(generation.updated_at)
    }
  end

  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp format_datetime(_value), do: nil
end
