defmodule TesseractStudio.Repo.Migrations.CreateEdges do
  use Ecto.Migration

  def change do
    create table(:edges) do
      add :edge_id, :string, null: false
      add :label, :string
      add :source_page_id, references(:pages, on_delete: :delete_all), null: false
      add :target_page_id, references(:pages, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:edges, [:project_id, :edge_id])
    create index(:edges, [:project_id])
    create index(:edges, [:source_page_id])
    create index(:edges, [:target_page_id])
  end
end
