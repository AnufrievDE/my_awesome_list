defmodule MyAwesomeList.Model.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :url, :string, null: false
      add :api_url, :string
      add :owner, :string
      add :name, :string
      add :description, :string
      add :stargazers_count, :integer
      add :pushed_at, :naive_datetime
      add :category_id, references(:categories)

      timestamps()
    end

    create unique_index(:repositories, [:url])
    create index(:repositories, [:owner, :name])
    create index(:repositories, [:api_url])
  end
end
