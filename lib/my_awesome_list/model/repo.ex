defmodule MyAwesomeList.Model.Repo do
  use Ecto.Repo,
    otp_app: :my_awesome_list,
    adapter: Ecto.Adapters.Postgres
end
