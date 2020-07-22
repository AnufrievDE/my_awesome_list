defmodule MyAwesomeList.Parser do
  @github_repo_url_regexp ~r{(^https?://(?:www\.)?(github\.com))(/([^/]+)/([^/]+))/?.*$}
  @github_repos_api "https://api.github.com/repos"
  @github_domain "github.com"

  @h1_tag "h1"
  @h2_tag "h2"
  @a_tag "a"
  @href_tag "href"
  @p_tag "p"
  @em_tag "em"
  @ul_tag "ul"
  @li_tag "li"

  ## Parse readme for the list of categories parts
  def split_by_categories!(readme_md_ast) do
    readme_md_ast
    |> Stream.drop_while(&(elem(&1, 0) !== @h2_tag))
    |> Enum.reduce_while([], fn
      el, acc when elem(el, 0) === @h1_tag ->
        {:halt, acc}
      el, acc when elem(el, 0) === @h2_tag ->
        {:cont, [[el] | acc]}
      el, [hd_list | t_acc] ->
        {:cont, [[el | hd_list] | t_acc]}
      end)
  end

  ## Parse readme md_ast part for params - for %Category{} creation
  def parse_for_c_params([], acc), do: {:ok, acc}
  def parse_for_c_params([{@h2_tag, [], [name], _} | t], acc) when is_binary(name) do
    parse_for_c_params(t, Map.merge(acc, %{name: name}))
  end
  def parse_for_c_params([{@p_tag, [], [ast], _} | t], acc) do
    parse_for_c_params([ast | t], acc)
  end
  def parse_for_c_params([{@em_tag, [], [d | d_t], _} | t], acc) when is_binary(d) do
    desc = parse_desc(d_t, d)
    parse_for_c_params(t, Map.merge(acc, %{description: desc}))
  end
  def parse_for_c_params([{@ul_tag, [], ast, _} | t], acc) when is_list(ast) do
    ## Put :updated_at to rs_params here if they were given for category... a bit dirty
    at_params = Map.take(acc, [:updated_at])
    rs_params = Enum.map(ast,
      &(with {:ok, params} <- parse_for_r_params(&1, at_params), do: params))
    parse_for_c_params(t, Map.merge(acc, %{repositories: rs_params}))
  end
  def parse_for_c_params(ast, _acc), do: {:error, {:badast,ast}}

  ## Parse readme md_ast part for params - for %Repository{} creation
  def parse_for_r_params({@li_tag, [], ast, _}, acc) do
    parse_for_r_params(ast, acc)
  end
  def parse_for_r_params([{@a_tag, [{@href_tag, url}], [name], _}, d | d_t], acc) do
    {:ok, params} = parse_url_for_r_params(url)
    desc = parse_desc(d_t, d)
    {:ok, Map.merge(acc,
      %{owner: params.owner, name: params.name || name,
        api_url: params.api_url, url: params.url || url, description: desc})
    }
  end
  def parse_for_r_params(ast, _acc), do: {:error, {:badast, ast}}

  ## Parse library url. Return library owner, name, api_url if it is github repo
  def parse_url_for_r_params(url) when is_binary(url) do
    case Regex.run(@github_repo_url_regexp, url) do
      [^url, site_url, @github_domain, alias, owner, name] ->
        ## github repo url, create api url:
        {:ok, %{owner: owner, name: name,
          api_url: @github_repos_api <> alias, url: site_url <> alias}}
      nil -> ## not github repo url:
        {:ok, %{owner: nil, name: nil, api_url: nil, url: nil}}
    end
  end
  def parse_url_for_r_params(url), do: {:error, {:badurl, url}}

  def parse_desc([], desc), do: desc
  def parse_desc([{_tag, _, [desc_part], _}, desc_end | t], desc_acc) do
    parse_desc(t, desc_acc <> desc_part <> desc_end)
  end

  def parse_gql_resp(json_body) do
    case json_body do
      %{"data" => %{
          "repository" => %{
            "url" => url,
            "stargazers" => %{"totalCount" => stars},
            "defaultBranchRef" => %{
              "target" => %{
                "history" => %{
                  "edges" => [
                    %{"node" => %{
                        "author" => %{"date" => date}
                      }
                    }
                  ]
                }
              }
            }
          }
        }
      } ->
        with {:ok, params} <- parse_url_for_r_params(url),
             {:ok, at} <- NaiveDateTime.from_iso8601(date),
          do: {:ok, Map.merge(params,
                %{url: url, stargazers_count: stars, pushed_at: at})}
      _ ->
        {:error, {:badresp, {:gql_resp, json_body}}}
    end
  end

  def parse_rest_resp(json_body) do
    case json_body do
      %{"html_url" => url,
        "pushed_at" => date, # it is not the last commit date, but better than nothing
        "stargazers_count" => stars} ->
        with {:ok, params} <- parse_url_for_r_params(url),
             {:ok, at} <- NaiveDateTime.from_iso8601(date),
          do: {:ok, Map.merge(params, %{pushed_at: at, stargazers_count: stars})}
      _ ->
        {:error, {:badrest, {:rest_resp, json_body}}}
    end
  end
end
