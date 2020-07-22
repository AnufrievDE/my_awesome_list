defmodule MyAwesomeList.Spider do
  use Crawly.Spider
  use TypedStruct

  alias MyAwesomeList.Parser
  alias MyAwesomeList.Model.Category, as: C
  alias MyAwesomeList.Model.Repository, as: R
  alias MyAwesomeList.Fetcher.GqlReq
  alias Crawly.ParsedItem
  alias Crawly.Request

  require Logger

  @github_api_domain "api.github.com"
  @github_graphql_api "https://api.github.com/graphql"

  defmodule Limit do
    typedstruct enforce: true do
      field :url, binary(), default: ""
      field :limit, integer()
      field :remain, integer()
      field :reset_at, DateTime.t()
    end
  end

  defp limit!(url, headers) do
    case Regex.match?(~r{#{@github_api_domain}}, url) do
      true -> %Limit{limit(headers) | url: url}
      false -> throw {:error, {:unknown_limits_for, url}}
    end
  end
  defp limit(headers) do ## retrieving api.github.com limits
    headers = Enum.into(headers, %{})
    limit = String.to_integer(headers["X-RateLimit-Limit"])
    remain = String.to_integer(headers["X-RateLimit-Remaining"])
    reset_at_unix = String.to_integer(headers["X-RateLimit-Reset"])
    reset_at = DateTime.from_unix!(reset_at_unix)

    %Limit{limit: limit, remain: remain, reset_at: reset_at}
  end

  @impl Crawly.Spider
  def base_url(), do: ""

  @readme_md_url "https://raw.githubusercontent.com/h4cc/awesome-elixir/master/README.md"
  @impl Crawly.Spider
  def init(), do: [start_urls: [@readme_md_url]]

  def headers() do
    case Application.get_env(:my_awesome_list, :github_api_token) do
      nil -> []
      token -> [authorization: "Bearer #{token}"]
    end
  end

  @impl Crawly.Spider
  def parse_item(%HTTPoison.Response{} = resp) do
      {:ok, parsed_item} =
        parse_response(resp.status_code, resp.request_url, resp)
      parsed_item
  end

  ## GraphQL request for url, stars, and last commit datetime
  @gql_stars_date_req """
  query($owner:String!, $name:String!){
    repository(owner: $owner, name: $name) {
      url
      stargazers {
        totalCount
      }
      defaultBranchRef {
        target {
          ... on Commit {
            history(first: 1) {
              edges {
                node {
                  author {
                    date
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  """

  ## HTTP Status codes:
  @ok 200
  @unauthorized 401
  @forbidden 403
  @not_found 404

  ## need to hardcode, if use middleware Crawly.Middlewares.RequestOptions
  ## then custom %GqlReq{} options will be lost in custom fetcher
  @conn_opts [follow_redirect: true]

  defp parse_response(@unauthorized, url, _resp),
    do: {:error, {:unauthorized, url}}
  defp parse_response(@not_found, url, _resp),
    do: {:error, {:not_found, url}}
  defp parse_response(@forbidden, url, resp) do
    l = %Limit{remain: 0} = limit!(url, resp.headers)
    {:error, {:limit_exceeded, l}}
  end
  defp parse_response(@ok, @readme_md_url, resp) do
    {:ok, md_ast, _} = EarmarkParser.as_ast(resp.body)

    at = MyAwesomeList.timestamp_seconds()
    categories =
    Parser.split_by_categories!(md_ast)
    |> Enum.map(&(with {:ok, c} <- C.from_md_ast(&1, %{updated_at: at}), do: c))

    requests =
      for c <- categories do
        for r <- c.repositories, r.api_url !== nil do
          vars = Map.take(r, [:owner, :name])
          create_github_gql_req(@gql_stars_date_req, vars, r.url, @conn_opts)
        end
      end |> List.flatten()

    {:ok, %ParsedItem{
      :requests => requests,
      :items => 1..length(categories) # fake items instead of categories
    }}
  end
  defp parse_response(@ok, @github_graphql_api, resp) do
    r_old = R.get_by(%{url: resp.request.params.url})
    result =
      with {:ok, json_map} <- Jason.decode(resp.body),
        do: Parser.parse_gql_resp(json_map)

    reqs =
      case result do
        {:ok, params} ->
          ## Update entry
          {:ok, _r} = R.update(r_old, Map.drop(params, [:url]))
          []
        {:error, _} ->
          [create_github_rest_req(r_old.api_url, @conn_opts)]
      end
    {:ok, %ParsedItem{
      :requests => reqs,
      :items => [1] # fake item instead of repository
    }}
  end
  defp parse_response(@ok, rest_api_url, resp) do
    {:ok, r} =
    with {:ok, json_map} <- Jason.decode(resp.body),
         {:ok, params} <- Parser.parse_rest_resp(json_map) do
      R.get_by(%{api_url: rest_api_url})
      |> R.update(Map.drop(params, [:url]))
    end
    reqs =
    case r.api_url do
      ^rest_api_url -> []
      _new -> vars = Map.take(r, [:owner, :name])
        [create_github_gql_req(@gql_stars_date_req, vars, r.url, @conn_opts)]
    end

    {:ok, %ParsedItem{
      :requests => reqs,
      :items => [1] # fake item instead of repository
    }}
  end

  defp create_github_gql_req(query, vars, url, headers \\ headers(), conn_opts) do
    gql_opts = %GqlReq{query: query, variables: vars, url: url}
    opts = %{httpoison_opts: conn_opts, gql_opts: gql_opts}
    Request.new(@github_graphql_api, headers, opts)
  end

  defp create_github_rest_req(rest_url, headers \\ headers(), conn_opts) do
    Request.new(rest_url, headers, conn_opts)
  end
end
