defmodule TesseractStudio.Studio.Flow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "flows" do
    field :name, :string
    field :node_id, :string
    field :content, :map, default: %{}
    field :position_x, :float, default: 0.0
    field :position_y, :float, default: 0.0

    belongs_to :project, TesseractStudio.Studio.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(flow, attrs) do
    flow
    |> cast(attrs, [:name, :content, :node_id, :position_x, :position_y, :project_id])
    |> validate_required([:name, :node_id, :project_id])
    |> unique_constraint([:project_id, :node_id])
  end

  def position_changeset(flow, attrs) do
    flow
    |> cast(attrs, [:position_x, :position_y])
  end
end
