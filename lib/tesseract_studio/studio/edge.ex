defmodule TesseractStudio.Studio.Edge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "edges" do
    field :edge_id, :string
    field :label, :string

    belongs_to :source_page, TesseractStudio.Studio.Page
    belongs_to :target_page, TesseractStudio.Studio.Page
    belongs_to :project, TesseractStudio.Studio.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(edge, attrs) do
    edge
    |> cast(attrs, [:edge_id, :label, :source_page_id, :target_page_id, :project_id])
    |> validate_required([:edge_id, :source_page_id, :target_page_id, :project_id])
    |> unique_constraint([:project_id, :edge_id])
    |> foreign_key_constraint(:source_page_id)
    |> foreign_key_constraint(:target_page_id)
  end
end
