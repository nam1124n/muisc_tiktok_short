defmodule Backend.Firebase.TokenCache do
  @moduledoc false

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  @spec get_valid_token() :: String.t() | nil
  def get_valid_token do
    Agent.get(__MODULE__, fn
      %{token: token, expires_at: expires_at}
      when is_binary(token) and is_integer(expires_at) ->
        if System.system_time(:second) < expires_at, do: token, else: nil

      _other ->
        nil
    end)
  end

  @spec put_token(String.t(), pos_integer()) :: :ok
  def put_token(token, expires_in_seconds)
      when is_binary(token) and is_integer(expires_in_seconds) and expires_in_seconds > 0 do
    expires_at = System.system_time(:second) + max(expires_in_seconds - 60, 60)
    Agent.update(__MODULE__, fn _state -> %{token: token, expires_at: expires_at} end)
  end
end
