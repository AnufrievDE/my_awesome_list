use Mix.Config

# Configure your database
config :my_awesome_list, MyAwesomeList.Model.Repo,
  username: "postgres",
  password: "postgres",
  database: "my_awesome_list_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 30

config :my_awesome_list,
  refresh_timeout: 30 # minutes between refreshes from readme_md

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :my_awesome_list, MyAwesomeListWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :my_awesome_list, MyAwesomeListWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/my_awesome_list_web/(live|views)/.*(ex)$",
      ~r"lib/my_awesome_list_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
config :logger, level: :info

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

import_config "dev.secret.exs"
