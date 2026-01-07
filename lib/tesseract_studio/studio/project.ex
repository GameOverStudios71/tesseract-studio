defmodule TesseractStudio.Studio.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :slug, :string
    field :description, :string

    belongs_to :user, TesseractStudio.Accounts.User
    has_many :pages, TesseractStudio.Studio.Page
    has_many :edges, TesseractStudio.Studio.Edge

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :slug, :description, :user_id])
    |> validate_required([:name, :user_id])
    |> generate_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> validate_length(:slug, min: 2, max: 100)
    |> unique_constraint([:user_id, :slug])
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
