defmodule MyAwesomeList.Model.Category do
  use Ecto.Schema

  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias MyAwesomeList.Parser
  alias MyAwesomeList.Model.Repo
  alias MyAwesomeList.Model.Repository, as: R
  alias __MODULE__, as: C

  schema "categories" do
    field :name, :string
    field :description, :string
    has_many :repositories, R
    timestamps()
  end

  @changeable [:name, :description, :updated_at]

  def changeset(c, params \\ %{}) do
    c
    |> Repo.preload(:repositories)
    |> cast(params, @changeable)
    |> put_assoc(:repositories,
      ## This is one by one upsert with R.changeset/2 called for each repository
      #Enum.map(params[:repositories] || [],
      #&(with {:ok, r} <- R.upsert(&1) do r end)))
      ##
      ## This is upsert_all without data check
      R.upsert_all(params[:repositories] || [], params[:updated_at]))
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end

  def list do
    import Ecto.Query
    rs_query = from r in R, order_by: r.name
    Repo.all from c in C, order_by: c.name, preload: [repositories: ^rs_query]
  end

  def get_by(params) do
    import Ecto.Query
    where = Enum.into(params, [])
    rs_query = from r in R, order_by: r.name
    Repo.one from c in C, where: ^where, preload:  [repositories: ^rs_query]
  end

  def create(params \\ %{}) do
    %C{} |> changeset(params) |> Repo.insert()
  end

  def update(%C{} = c, params \\ %{}) do
    c |> changeset(params) |> Repo.update()
  end

  def delete(%C{} = c) do
    Repo.delete(c)
  end

  def upsert(%{} = params) do
    %C{}
    |> changeset(params)
    |> Repo.insert(conflict_target: [:name],
      on_conflict: {:replace, @changeable})
  end

  def from_md_ast(md_ast, %{} = params \\ %{}) do
    # set :updated_at to current timestamp if not set
    Map.put_new_lazy(params, :updated_at, &(MyAwesomeList.timestamp_seconds/0))
    |> fn params ->
        with {:ok, params} <- Parser.parse_for_c_params(md_ast, params),
          do: params
      end.()
    |> upsert()
  end
end
