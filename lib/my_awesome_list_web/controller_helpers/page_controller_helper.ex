defmodule MyAwesomeListWeb.PageControllerHelper do
  use TypedStruct

  alias NaiveDateTime, as: NDT
  alias StarsInfo, as: SI

  defmodule StarsInfo do
    typedstruct enforce: true do
      field :min, integer(), default: 0
      field :max, integer(), default: 0
      field :sum, integer(), default: 0
      field :mean, integer(), default: 0
      field :curr, integer(), enforce: false
    end
  end

  @day_seconds 86400

  def at_to_days_ago(:unknown), do: :unknown
  def at_to_days_ago(nil), do: :unknown
  def at_to_days_ago(%NDT{} = at),
    do: div(NDT.diff(NDT.utc_now(), at, :second), @day_seconds)

  defp transform_repository(r, stars_info) do
    days_ago = at_to_days_ago(r.pushed_at)
    Map.merge(r, %{importance:
      importance(days_ago, %SI{stars_info | curr: r.stargazers_count}),
      updated_days_ago: days_ago})
  end

  def transform_category(%{repositories: rs} = c) do
    c_stars_info = repositories_stars_info(rs)
    Map.merge(c, %{repositories: [], libs:
      Enum.map(rs, &(transform_repository(&1, c_stars_info)))})
  end

  def filter_by_stars(cs, min_stars) when is_integer(min_stars) and min_stars > 0 do
    cs
    |> Enum.map(fn c ->
      %{c | repositories: Enum.filter(c.repositories,
        &((&1.stargazers_count || 0) >= min_stars))}
    end)
  end
  def filter_by_stars(cs, _), do: cs

  def filter_by_libs_presence(cs) do
    cs |> Enum.filter(fn c -> Enum.count(c.repositories) > 0 end)
  end

def repositories_stars_info([%{stargazers_count: sc}]) do
  %SI{min: sc, max: sc, mean: sc, sum: sc}
end
def repositories_stars_info(rs) do
    stars = for r <- rs, r.stargazers_count !== nil,
      do: r.stargazers_count
    ## it is better to calculate weights for stars and weighted average here
    ## but... later
    case stars do
      [] -> %SI{}
      _ ->
        min = Enum.min(stars)
        max = Enum.max(stars)
        sum = Enum.sum(stars)
        mean = div sum, length(stars)
        %SI{min: min, max: max, mean: mean, sum: sum}
    end
  end

  @days_imp_w 0.25
  @stars_imp_w 0.75

  @days_ago_worst_score 365
  @no_imp_levels 5
  @imp_1 1
  @imp_2 2
  @imp_default ceil(@no_imp_levels / 2)

  def importance(_, %SI{curr: nil}), do: @imp_default
  def importance(_, %SI{curr: v, max: v, min: v}), do: 1
  def importance(_, %SI{curr: v1, max: v1, min: v2, sum: s}) when s == v1 + v2, do: @imp_1
  def importance(_, %SI{curr: v1, min: v1, max: v2, sum: s}) when s == v1 + v2, do: @imp_2
  def importance(days_ago, %SI{min: s_min, mean: s_mean, curr: stars}) do
    days_imp_step = div(@days_ago_worst_score, @no_imp_levels - 1)
    days_imp_v = (div(min(days_ago, @days_ago_worst_score), days_imp_step) + 1)

    #stars_imp_step = min(div(s_max - s_min, @no_imp_levels - 1), s_mean)
    stars_imp_step = div(s_mean - s_min, @imp_default)
    stars_imp_v = @no_imp_levels -
      (div(min(stars - s_min, (@no_imp_levels-1)*stars_imp_step), stars_imp_step))
    ceil(Float.round(days_imp_v*@days_imp_w + stars_imp_v*@stars_imp_w))
  end
end
