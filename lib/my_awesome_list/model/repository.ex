defmodule MyAwesomeList.Model.Repository do
  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias MyAwesomeList.Parser
  alias MyAwesomeList.Model.Repo
  alias MyAwesomeList.Model.Category, as: C
  alias __MODULE__, as: R

  require Ecto.Query

  schema "repositories" do
    field :url, :string
    field :api_url, :string
    field :owner, :string
    field :name, :string
    field :description, :string
    field :stargazers_count, :integer
    field :pushed_at, :naive_datetime
    belongs_to :category, C
    timestamps()
  end

  @changeable [:owner, :name, :url, :api_url, :description,
    :stargazers_count, :pushed_at, :updated_at]

  def changeset(r, params \\ %{}) do
    r
    |> cast(params, @changeable)
    |> validate_required([:url])
    |> unique_constraint(:url)
  end

  def list do
    R |> Ecto.Query.order_by(asc: :name) |> Repo.all()
  end

  def get_by(%{} = params), do: Repo.get_by(R, params)

  def create(%{} = params \\ %{}) do
    %R{} |> changeset(params) |> Repo.insert()
  end

  def update(%R{} = r, %{} = params) do
    r |> changeset(params) |> Repo.update()
  end

  def delete(%R{} = r) do
    Repo.delete(r)
  end

  def upsert(%{} = params) do
    ## explicitly add :updated_at to list of fields to replace on conflict
    fields_to_replace =
      Enum.uniq([:updated_at | Map.keys(Map.take(params, @changeable))])
    %R{}
    |> changeset(params)
    |> Repo.insert(conflict_target: [:url],
      on_conflict: {:replace, fields_to_replace})
  end

  #############################################################################
  ### upsert_all/2
  ### Assumes that all the rs_params has the same fields to upsert!
  ###
  ### Keys from the first r_params are taken and those are @changeable will be
  ### replaced on_conflict at insertation of all rs_params entries.
  ###
  ### at entry update(conflict):
  ### - r_params with less keys than in first r_params, will override part of
  ### old entry values with nil values for part of fields;
  ### - r_params with more keys than in first r_params, will be considered
  ### partly: values for the keys which are absent in first r_params will not
  ### be set (old entry values remain).
  #############################################################################
  def upsert_all(rs_params, rs_at \\ MyAwesomeList.timestamp_seconds())
  def upsert_all(rs_params, nil), do: upsert_all(rs_params)
  def upsert_all(rs_params, rs_at) do
    ## need to set timestamps for all rs_params explicitly if not set
    mandatory_timestamps = %{inserted_at: rs_at, updated_at: rs_at}
    rs_params = Enum.map(rs_params, &(Map.merge(mandatory_timestamps, &1)))

    ## Dynamic calculation of fields to replace is needed to avoid
    ## reseting of already set fields to nil values at update of part of fields
    ## (e.g. to not to override stars/pushed_at at C.upsert/1 from readme_md)
    fields_to_replace =
      Map.keys(Map.take(List.first(rs_params) || %{}, @changeable))

    {_n, rs} = Repo.insert_all(R, rs_params,
      conflict_target: [:url],
      on_conflict: {:replace, fields_to_replace},
      returning: true)
    rs
  end

  def from_md_ast(md_ast, %{} = params \\ %{}) do
    # set :updated_at to current timestamp if not set
    Map.put_new_lazy(params, :updated_at, &(MyAwesomeList.timestamp_seconds/0))
    |> fn params ->
        with {:ok, params} <- Parser.parse_for_r_params(md_ast, params),
          do: params
      end.()
    |> upsert()
  end
end
