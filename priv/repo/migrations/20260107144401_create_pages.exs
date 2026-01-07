defmodule TesseractStudio.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :content, :map, default: %{}
      add :node_id, :string, null: false
      add :position_x, :float, default: 0.0
      add :position_y, :float, default: 0.0
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pages, [:project_id, :slug])
    create unique_index(:pages, [:project_id, :node_id])
    create index(:pages, [:project_id])
  end
end
