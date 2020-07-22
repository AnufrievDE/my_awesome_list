# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :my_awesome_list,
  ecto_repos: [MyAwesomeList.Model.Repo]

# Configures the endpoint
config :my_awesome_list, MyAwesomeListWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wcFrH9Q4mzT3ZdsGiphLhChScI1sGeGyBxVjV+kRQf3jA8TgYtUsXmw4h9sKb9+T",
  render_errors: [view: MyAwesomeListWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MyAwesomeList.PubSub,
  live_view: [signing_salt: "80BMTTHg"]

config :crawly,
  closespider_itemcount: 5000,
  closespider_timeout: 1,
  concurrent_requests_per_domain: 100,
  fetcher: {MyAwesomeList.Fetcher, []},
  middlewares: [
    {Crawly.Middlewares.UserAgent, user_agents: ["Elixir Awesome List Parser"] }
  ],
  retry: [max_retries: 1],
  on_spider_closed_callback: &MyAwesomeList.start_supervised_spider_task/1

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
