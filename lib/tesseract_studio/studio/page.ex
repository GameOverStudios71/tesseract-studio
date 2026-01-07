defmodule TesseractStudio.Studio.Page do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :name, :string
    field :slug, :string
    field :content, :map, default: %{}
    field :node_id, :string
    field :position_x, :float, default: 0.0
    field :position_y, :float, default: 0.0

    belongs_to :project, TesseractStudio.Studio.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:name, :slug, :content, :node_id, :position_x, :position_y, :project_id])
    |> validate_required([:name, :node_id, :project_id])
    |> generate_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> validate_length(:slug, min: 1, max: 100)
    |> unique_constraint([:project_id, :slug])
    |> unique_constraint([:project_id, :node_id])
  end

  def position_changeset(page, attrs) do
    page
    |> cast(attrs, [:position_x, :position_y])
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        case get_change(changeset, :name) do
          nil -> changeset
          name -> put_change(changeset, :slug, slugify(name))
        end

      _ ->
        changeset
    end
  end

  defp slugify(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
