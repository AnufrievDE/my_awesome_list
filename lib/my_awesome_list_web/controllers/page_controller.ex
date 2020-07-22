defmodule MyAwesomeListWeb.PageController do
  use MyAwesomeListWeb, :controller
  import MyAwesomeListWeb.PageControllerHelper

  def index(conn, params) do
    min_stars = String.to_integer(params["min_stars"] || "0")
    categories =
      MyAwesomeList.Model.Category.list()
      |> filter_by_stars(min_stars)
      |> filter_by_libs_presence()
      |> Enum.map(&(transform_category/1))
    render(conn, "index.html", %{categories: categories})
  end
end
