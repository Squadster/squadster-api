use Mix.Config

require Logger

defmodule EnvHelper do
  def safe_env(env, default \\ "", raise_for_prod \\ true) do
    value = System.get_env(env)

    if is_nil(value) do
      if Mix.env == :prod && raise_for_prod do
        raise "config error: required environment variable #{env} is unset"
      end

      Logger.warn("environment variable #{env} is unset, using default \"#{default}\" for config")

      default
    else
      value
    end
  end
end

# URL references
config :squadster,
  ecto_repos: [Squadster.Repo],
  frontend_url: EnvHelper.safe_env("FRONTEND_URL", "squadster.wtf:3000"),
  bot_url: EnvHelper.safe_env("BOT_URL", "squadster.wtf:5000"),
  bot_token: EnvHelper.safe_env("BOT_TOKEN")

# Configures the endpoint
config :squadster, SquadsterWeb.Endpoint,
  url: [host: EnvHelper.safe_env("HOSTNAME", "squadster.wtf")],
  secret_key_base: EnvHelper.safe_env("SECRET_KEY_BASE", "dummy secret key"),
  render_errors: [view: SquadsterWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Squadster.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :gettext, :default_locale, "ru"

import_config "oauth.exs"
import_config "scheduler.exs"
import_config "mailer.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
