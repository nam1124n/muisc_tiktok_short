defmodule Backend.Music.SunoClient do
  @moduledoc """
  Thin HTTP client for the Suno API provider.

  The Flutter app continues to talk only to the local Phoenix backend.
  """

  @generate_path "/api/v1/generate"
  @record_info_path "/api/v1/generate/record-info"
  @timeout_ms 45_000
  @rotation_error_types [:insufficient_credits, :unauthorized, :rate_limited]

  @spec enabled?() :: boolean()
  def enabled? do
    config()[:enabled] == true and available_accounts() != []
  end

  @spec generate_music(String.t()) ::
          {:ok, %{task_id: String.t(), account_alias: String.t()}} | {:error, String.t()}
  def generate_music(prompt) when is_binary(prompt) do
    case rotation_accounts() do
      [] ->
        {:error, "Suno account chưa được cấu hình"}

      accounts ->
        try_generate_music(prompt, accounts, nil)
    end
  end

  @spec get_generation(String.t(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def get_generation(task_id, opts \\ [])

  def get_generation(task_id, opts) when is_binary(task_id) and task_id != "" and is_list(opts) do
    path = "#{@record_info_path}?taskId=#{URI.encode_www_form(task_id)}"
    account_alias = Keyword.get(opts, :account_alias)

    with {:ok, account} <- fetch_account(account_alias),
         {:ok, response} <- request(:get, path, nil, account),
         {:ok, data} <- fetch_success_data(response) do
      {:ok, data}
    else
      {:error, _type, message} -> {:error, message}
      {:error, message} -> {:error, message}
    end
  end

  defp try_generate_music(_prompt, [], {:error, message}), do: {:error, message}
  defp try_generate_music(_prompt, [], nil), do: {:error, "Suno account chưa được cấu hình"}

  defp try_generate_music(prompt, [account | rest], _last_error) do
    case generate_music_with_account(prompt, account) do
      {:ok, task_id} ->
        {:ok, %{task_id: task_id, account_alias: account_alias(account)}}

      {:error, type, message} when type in @rotation_error_types and rest != [] ->
        try_generate_music(prompt, rest, {:error, message})

      {:error, _type, message} ->
        {:error, message}

      {:error, message} ->
        {:error, message}
    end
  end

  defp generate_music_with_account(prompt, account) do
    callback_url = account[:callback_url]

    if is_binary(callback_url) and callback_url != "" do
      with {:ok, response} <-
             request(
               :post,
               @generate_path,
               %{
                 customMode: false,
                 instrumental: account[:instrumental] == true,
                 model: account[:model] || "V5",
                 callBackUrl: callback_url,
                 prompt: String.trim(prompt)
               },
               account
             ),
           {:ok, data} <- fetch_success_data(response),
           task_id when is_binary(task_id) and task_id != "" <- data["taskId"] do
        {:ok, task_id}
      else
        {:error, type, message} ->
          {:error, type, message}

        {:error, message} ->
          {:error, message}

        _unexpected ->
          {:error, "Suno không trả về taskId hợp lệ"}
      end
    else
      {:error, :invalid_account,
       "Suno callback URL chưa được cấu hình cho #{account_alias(account)}"}
    end
  end

  defp request(method, path, payload, account) do
    ensure_http_stack_started()

    case :httpc.request(
           method,
           request_tuple(method, path, payload, account),
           http_options(),
           request_options()
         ) do
      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, body}}
      when status_code in 200..299 ->
        decode_json(body)

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, body}} ->
        with {:ok, decoded} <- decode_json(body) do
          decode_error_tuple(decoded, "Suno request thất bại (HTTP #{status_code})")
        else
          _error -> {:error, "Suno request thất bại (HTTP #{status_code})"}
        end

      {:error, reason} ->
        {:error, "Không thể kết nối tới Suno: #{format_reason(reason)}"}
    end
  end

  defp request_tuple(:post, path, payload, account) do
    {
      request_url(path, account),
      request_headers(account),
      ~c"application/json",
      Jason.encode!(payload)
    }
  end

  defp request_tuple(:get, path, _payload, account) do
    {request_url(path, account), request_headers(account)}
  end

  defp request_url(path, account) do
    base_url = account[:api_base_url] |> to_string() |> String.replace(~r{/+$}, "")

    "#{base_url}#{path}"
    |> String.to_charlist()
  end

  defp request_headers(account) do
    [
      {~c"Authorization", "Bearer #{account[:api_key]}" |> String.to_charlist()},
      {~c"Content-Type", ~c"application/json"}
    ]
  end

  defp http_options do
    [timeout: @timeout_ms, connect_timeout: 15_000]
  end

  defp request_options do
    [body_format: :binary]
  end

  defp fetch_success_data(%{"code" => 200, "data" => data}) when is_map(data), do: {:ok, data}

  defp fetch_success_data(%{"code" => code} = response) when is_integer(code) do
    decode_error_tuple(response, "Suno request thất bại")
  end

  defp fetch_success_data(%{"msg" => message} = response) when is_binary(message) do
    decode_error_tuple(response, message)
  end

  defp fetch_success_data(_response), do: {:error, "Suno trả về dữ liệu không hợp lệ"}

  defp decode_json(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
      _error -> {:error, "Suno trả về JSON không hợp lệ"}
    end
  end

  defp decode_error_message(response, fallback) when is_map(response) do
    data = Map.get(response, "data")

    cond do
      is_binary(get_in(data || %{}, ["errorMessage"])) and
          get_in(data || %{}, ["errorMessage"]) != "" ->
        get_in(data || %{}, ["errorMessage"])

      is_binary(response["msg"]) and response["msg"] != "" ->
        response["msg"]

      true ->
        fallback
    end
  end

  defp decode_error_tuple(response, fallback) when is_map(response) do
    message = decode_error_message(response, fallback)

    case error_type(response) do
      nil -> {:error, message}
      type -> {:error, type, message}
    end
  end

  defp error_type(%{"code" => code}) when code in [401], do: :unauthorized
  defp error_type(%{"code" => code}) when code in [405, 430], do: :rate_limited
  defp error_type(%{"code" => code}) when code in [429], do: :insufficient_credits
  defp error_type(_response), do: nil

  defp rotation_accounts do
    active_alias = config()[:active_account_alias]

    available_accounts()
    |> Enum.sort_by(fn account ->
      if account_alias(account) == active_alias, do: 0, else: 1
    end)
  end

  defp fetch_account(nil) do
    case rotation_accounts() do
      [account | _rest] -> {:ok, account}
      [] -> {:error, "Suno account chưa được cấu hình"}
    end
  end

  defp fetch_account(account_alias) when is_binary(account_alias) do
    case Enum.find(available_accounts(), fn account -> account_alias(account) == account_alias end) do
      nil -> {:error, "Không tìm thấy Suno account alias: #{account_alias}"}
      account -> {:ok, account}
    end
  end

  defp available_accounts do
    config()
    |> Keyword.get(:accounts, [])
    |> Enum.filter(fn account ->
      is_map(account) and
        is_binary(account[:api_key]) and String.trim(account[:api_key]) != "" and
        is_binary(account[:callback_url]) and String.trim(account[:callback_url]) != ""
    end)
  end

  defp account_alias(account) when is_map(account) do
    account[:alias] || account[:provider_account] || "primary"
  end

  defp ensure_http_stack_started do
    _ = Application.ensure_all_started(:inets)
    _ = Application.ensure_all_started(:ssl)
    :ok
  end

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(reason), do: inspect(reason)

  defp config do
    Application.get_env(:backend, :suno, [])
  end
end
