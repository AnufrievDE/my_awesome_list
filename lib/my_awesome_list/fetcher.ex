defmodule MyAwesomeList.Fetcher do
  @moduledoc """
  Implements Crawly.Fetchers.Fetcher behavior based on HTTPoison HTTP client
  """
  @behaviour Crawly.Fetchers.Fetcher
  use TypedStruct

  require Logger

  defmodule GqlReq do
    typedstruct enforce: true do
      field :url, binary, default: ""
      field :query, binary(), default: ""
      field :variables, map(), default: %{}
    end
  end

  def fetch(gql_req = %{:options => %{:gql_opts => gql_opts = %GqlReq{}}}, _) do
    ## Post body construction, taken from Neuron.query/3
    ## It is better to return pure HTTPoison response
    conn_opts = gql_req.options.httpoison_opts
    body =
    Neuron.Fragment.insert_into_query(gql_opts.query)
    |> build_body()
    |> insert_variables(gql_opts.variables)
    |> Jason.encode!()
    headers =
      [{'Content-Type', "application/json"} | gql_req.headers] |> Enum.uniq()
    with {:ok, resp} <- HTTPoison.post(gql_req.url, body, headers, conn_opts),
      do: {:ok, %{resp | request:
            %{resp.request | params:
              Map.merge(resp.request.params, %{url: gql_opts.url})}}}

  end
  def fetch(rest_req, _client_options) do
    HTTPoison.get(rest_req.url, rest_req.headers, rest_req.options)
  end

  defp build_body(query_string), do: %{query: query_string}

  defp insert_variables(body, variables) do
    Map.put(body, :variables, variables)
  end
end
