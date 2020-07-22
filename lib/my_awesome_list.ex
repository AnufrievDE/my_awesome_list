defmodule MyAwesomeList do
  @moduledoc false
  use Application

  alias NaiveDateTime, as: NDT

  require Logger

  def timestamp_seconds(), do: NDT.utc_now() |> NDT.truncate(:second)

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      MyAwesomeList.Model.Repo,
      # Start the Telemetry supervisor
      MyAwesomeListWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MyAwesomeList.PubSub},
      # Start the Endpoint (http/https)
      MyAwesomeListWeb.Endpoint,
      # Task Supervisor
      {Task.Supervisor, name: MyAwesomeList.TaskSupervisor},
      # The first task for the Task Supervisor
      {Task, &start_supervised_spider_task/0}
    ]

    opts = [strategy: :one_for_one, name: MyAwesomeList.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_supervised_spider_task(spider_stop_reason) do
    Logger.info("Spider stop reason: #{inspect(spider_stop_reason)}")
    n = Application.get_env(:my_awesome_list, :refresh_timeout)
    Logger.info("Schedule the next start of spider after #{n} minutes")
    :timer.apply_after(60000*n, __MODULE__, :start_supervised_spider_task, [])
  end

  def start_supervised_spider_task() do
    Task.Supervisor.start_child(MyAwesomeList.TaskSupervisor,
      &start_spider_task/0, restart: :transient)
  end

  def start_spider_task() do
    :ok = Crawly.Engine.start_spider(MyAwesomeList.Spider)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MyAwesomeListWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
