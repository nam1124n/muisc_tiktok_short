import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/backend start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :backend, BackendWeb.Endpoint, server: true
end

config :backend, BackendWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

backend_public_base_url = System.get_env("BACKEND_PUBLIC_BASE_URL", "") |> String.trim()

suno_callback_url =
  case System.get_env("SUNO_CALLBACK_URL") do
    nil ->
      case backend_public_base_url do
        "" -> ""
        base_url -> "#{String.replace(base_url, ~r{/+$}, "")}/api/suno/callback"
      end

    callback_url ->
      String.trim(callback_url)
  end

default_suno_base_url = "https://api.sunoapi.org"
default_suno_model = "V5"
default_suno_instrumental = true
active_suno_account_alias = "primary"

# Edit the keys directly here when you want to rotate accounts.
# Keep `alias` stable so old tasks can remember which key created them.
suno_accounts =
  if config_env() == :test do
    []
  else
    [
      %{
        alias: "primary",
        provider_account: "primary",
        api_base_url: default_suno_base_url,
        api_key: "ba1e76f2eba24d35cfbf0b066e0c3471",
        callback_url: suno_callback_url,
        model: default_suno_model,
        instrumental: default_suno_instrumental
      },
      %{
        alias: "backup_1",
        provider_account: "backup_1",
        api_base_url: default_suno_base_url,
        api_key: "",
        callback_url: suno_callback_url,
        model: default_suno_model,
        instrumental: default_suno_instrumental
      }
    ]
  end

config :backend, :suno,
  enabled:
    config_env() != :test and suno_callback_url != "" and
      Enum.any?(suno_accounts, fn account ->
        is_binary(account[:api_key]) and String.trim(account[:api_key]) != ""
      end),
  active_account_alias: active_suno_account_alias,
  accounts: suno_accounts,
  fallback_poll_interval_ms:
    System.get_env("SUNO_FALLBACK_POLL_INTERVAL_MS", "10000")
    |> String.to_integer()

cloudinary_cloud_name = System.get_env("CLOUDINARY_CLOUD_NAME", "") |> String.trim()
cloudinary_upload_preset = System.get_env("CLOUDINARY_UPLOAD_PRESET", "") |> String.trim()

config :backend, :cloudinary,
  enabled:
    config_env() != :test and cloudinary_cloud_name != "" and cloudinary_upload_preset != "",
  cloud_name: cloudinary_cloud_name,
  upload_preset: cloudinary_upload_preset

firebase_backend_email = System.get_env("FIREBASE_BACKEND_EMAIL", "") |> String.trim()
firebase_backend_password = System.get_env("FIREBASE_BACKEND_PASSWORD", "") |> String.trim()
firebase_project_id = System.get_env("FIREBASE_PROJECT_ID", "") |> String.trim()
firebase_web_api_key = System.get_env("FIREBASE_WEB_API_KEY", "") |> String.trim()

config :backend, :firestore_sync,
  enabled:
    config_env() != :test and firebase_backend_email != "" and firebase_backend_password != "" and
      firebase_project_id != "" and firebase_web_api_key != "",
  project_id: firebase_project_id,
  web_api_key: firebase_web_api_key,
  email: firebase_backend_email,
  password: firebase_backend_password

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :backend, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :backend, BackendWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :backend, BackendWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :backend, BackendWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
