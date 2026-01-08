defmodule TesseractStudio.Repo.Migrations.CreateFlows do
  use Ecto.Migration

  def change do
    create table(:flows) do
      add :name, :string, null: false
      add :node_id, :string, null: false
      add :content, :map, default: "{}"
      add :position_x, :float, default: 0.0
      add :position_y, :float, default: 0.0
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:flows, [:project_id])
    create unique_index(:flows, [:project_id, :node_id])
  end
end
