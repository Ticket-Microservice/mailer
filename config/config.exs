# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mailer,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :mailer, MailerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: MailerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mailer.PubSub,
  live_view: [signing_salt: "ZLYIUQjo"]

config :swoosh, :api_client, Swoosh.ApiClient.Hackney

config :mailer, Mailer.Mailer,
  adapter: Swoosh.Adapters.Gmail

config :mailer, Mailer.GmailOAuth2,
  client_id: System.get_env("GMAIL_CLIENT_ID"),
  client_secret: System.get_env("GMAIL_CLIENT_SECRET"),
  redirect_uri: "http://localhost:4004", # Replace with your redirect URI
  token_url: "https://oauth2.googleapis.com/token",
  auth_url: "https://accounts.google.com/o/oauth2/auth",
  refresh_token: System.get_env("GMAIL_REFRESH_TOKEN")

  # Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :mailer, Mailer.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
