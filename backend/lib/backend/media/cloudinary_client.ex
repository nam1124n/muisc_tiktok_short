defmodule Backend.Media.CloudinaryClient do
  @moduledoc """
  Downloads generated assets and stores them in Cloudinary.
  """

  @request_timeout_ms 90_000

  @spec enabled?() :: boolean()
  def enabled? do
    config()[:enabled] == true and
      config()[:cloud_name] not in [nil, ""] and
      config()[:upload_preset] not in [nil, ""]
  end

  @spec cloudinary_url?(String.t() | nil) :: boolean()
  def cloudinary_url?(url) when is_binary(url) do
    String.contains?(url, ".cloudinary.com/") or String.contains?(url, "res.cloudinary.com/")
  end

  def cloudinary_url?(_url), do: false

  @spec persist_remote_asset(String.t() | nil, keyword()) ::
          {:ok, String.t() | nil} | {:error, String.t()}
  def persist_remote_asset(url, opts \\ [])

  def persist_remote_asset(url, _opts) when url in [nil, ""], do: {:ok, nil}

  def persist_remote_asset(url, opts) when is_binary(url) and is_list(opts) do
    cleaned_url = String.trim(url)
    resource_type = Keyword.get(opts, :resource_type, "raw")
    default_content_type = Keyword.get(opts, :default_content_type, "application/octet-stream")

    cond do
      cleaned_url == "" ->
        {:ok, nil}

      not enabled?() ->
        {:ok, cleaned_url}

      cloudinary_url?(cleaned_url) ->
        {:ok, cleaned_url}

      true ->
        with {:ok, binary, content_type} <- download_binary(cleaned_url, default_content_type),
             {:ok, secure_url} <- upload_binary(binary, content_type, resource_type) do
          {:ok, secure_url}
        end
    end
  end

  defp download_binary(url, default_content_type) do
    ensure_http_stack_started()

    case :httpc.request(:get, {String.to_charlist(url), []}, http_options(), request_options()) do
      {:ok, {{_http_version, status_code, _reason_phrase}, headers, body}}
      when status_code in 200..299 and is_binary(body) ->
        {:ok, body, response_content_type(headers, default_content_type)}

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, _body}} ->
        {:error, "Tải file từ Suno thất bại (HTTP #{status_code})"}

      {:error, reason} ->
        {:error, "Không thể tải file từ Suno: #{format_reason(reason)}"}
    end
  end

  defp upload_binary(binary, content_type, resource_type) when is_binary(binary) do
    ensure_http_stack_started()

    data_uri = "data:#{content_type};base64,#{Base.encode64(binary)}"

    body =
      URI.encode_query(%{
        "upload_preset" => config()[:upload_preset],
        "file" => data_uri
      })

    case :httpc.request(
           :post,
           {upload_url(resource_type), request_headers(), ~c"application/x-www-form-urlencoded",
            body},
           http_options(),
           request_options()
         ) do
      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}}
      when status_code in 200..299 ->
        with {:ok, decoded} <- decode_json(response_body),
             secure_url when is_binary(secure_url) and secure_url != "" <- decoded["secure_url"] do
          {:ok, secure_url}
        else
          _unexpected -> {:error, "Cloudinary không trả về secure_url hợp lệ"}
        end

      {:ok, {{_http_version, status_code, _reason_phrase}, _headers, response_body}} ->
        with {:ok, decoded} <- decode_json(response_body) do
          {:error,
           decode_error_message(decoded, "Upload Cloudinary thất bại (HTTP #{status_code})")}
        else
          _error -> {:error, "Upload Cloudinary thất bại (HTTP #{status_code})"}
        end

      {:error, reason} ->
        {:error, "Không thể upload lên Cloudinary: #{format_reason(reason)}"}
    end
  end

  defp upload_url(resource_type) do
    "https://api.cloudinary.com/v1_1/#{config()[:cloud_name]}/#{resource_type}/upload"
    |> String.to_charlist()
  end

  defp request_headers do
    [{~c"Content-Type", ~c"application/x-www-form-urlencoded"}]
  end

  defp http_options do
    [timeout: @request_timeout_ms, connect_timeout: 15_000]
  end

  defp request_options do
    [body_format: :binary]
  end

  defp response_content_type(headers, default_content_type) when is_list(headers) do
    headers
    |> Enum.find_value(default_content_type, fn
      {key, value} ->
        if String.downcase(to_string(key)) == "content-type" do
          value
          |> to_string()
          |> String.split(";", parts: 2)
          |> List.first()
          |> String.trim()
        end

      _other ->
        nil
    end)
  end

  defp decode_json(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
      _error -> {:error, "Cloudinary trả về JSON không hợp lệ"}
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
    Application.get_env(:backend, :cloudinary, [])
  end
end
