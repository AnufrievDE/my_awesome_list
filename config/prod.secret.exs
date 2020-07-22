# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

# Configure your database
db_name =
  System.get_env("POSTGRES_DB") ||
    raise """
    environment variable POSTGRES_DB is missing.
    """
db_user =
  System.get_env("POSTGRES_USER") ||
    raise """
    environment variable POSTGRES_USER is missing.
    """

db_password =
  System.get_env("POSTGRES_PASSWORD") ||
    raise """
    environment variable POSTGRES_PASSWORD is missing.
    """

db_host =
  System.get_env("POSTGRES_HOST") ||
    raise """
    environment variable POSTGRES_HOST is missing.
    """

db_port =
  System.get_env("POSTGRES_PORT") ||
    raise """
    environment variable POSTGRES_PORT is missing.
    """

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """
github_api_token =
  System.get_env("GITHUB_API_TOKEN") ||
    raise """
    environment variable GITHUB_API_TOKEN is missing.
    """

config :my_awesome_list,
    github_api_token: github_api_token

config :my_awesome_list, MyAwesomeList.Model.Repo,
    username: db_user,
    password: db_password,
    database: db_name,
    hostname: db_host,
    show_sensitive_data_on_connection_error: true,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "30")

config :my_awesome_list, MyAwesomeListWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :my_awesome_list, MyAwesomeListWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
