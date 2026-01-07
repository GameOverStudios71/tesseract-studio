defmodule TesseractStudio.Studio do
  @moduledoc """
  The Studio context - manages projects, pages, and edges for the visual builder.
  """

  import Ecto.Query, warn: false
  alias TesseractStudio.Repo
  alias TesseractStudio.Studio.{Project, Page, Edge}

  # ============================================================================
  # Projects
  # ============================================================================

  @doc """
  Returns the list of projects for a user.
  """
  def list_projects(user_id) do
    Project
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], desc: p.updated_at)
    |> Repo.all()
  end

  @doc """
  Gets a single project.
  Raises `Ecto.NoResultsError` if the Project does not exist.
  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Gets a project by user and slug.
  """
  def get_project_by_slug(user_id, slug) do
    Repo.get_by(Project, user_id: user_id, slug: slug)
  end

  @doc """
  Gets a project by slug only (for public pages).
  """
  def get_project_by_slug!(slug) do
    Repo.get_by!(Project, slug: slug)
  end

  @doc """
  Creates a project.
  """
  def create_project(user, attrs \\ %{}) do
    %Project{}
    |> Project.changeset(Map.put(attrs, "user_id", user.id))
    |> Repo.insert()
  end

  @doc """
  Updates a project.
  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.
  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.
  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  # ============================================================================
  # Pages
  # ============================================================================

  @doc """
  Returns the list of pages for a project.
  """
  def list_pages(project_id) do
    Page
    |> where([p], p.project_id == ^project_id)
    |> order_by([p], asc: p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single page.
  """
  def get_page!(id), do: Repo.get!(Page, id)

  @doc """
  Gets a page by project and slug.
  """
  def get_page_by_slug(project_id, slug) do
    Repo.get_by(Page, project_id: project_id, slug: slug)
  end

  @doc """
  Gets a page by project and node_id.
  """
  def get_page_by_node_id(project_id, node_id) do
    Repo.get_by(Page, project_id: project_id, node_id: node_id)
  end

  @doc """
  Creates a page (when a node is added to the canvas).
  """
  def create_page(project, attrs \\ %{}) do
    %Page{}
    |> Page.changeset(Map.put(attrs, "project_id", project.id))
    |> Repo.insert()
  end

  @doc """
  Updates a page.
  """
  def update_page(%Page{} = page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates page position (when node is moved).
  """
  def update_page_position(%Page{} = page, x, y) do
    page
    |> Page.position_changeset(%{position_x: x, position_y: y})
    |> Repo.update()
  end

  @doc """
  Updates page content.
  """
  def update_page_content(%Page{} = page, content) do
    page
    |> Page.changeset(%{content: content})
    |> Repo.update()
  end

  @doc """
  Deletes a page (when node is removed from canvas).
  """
  def delete_page(%Page{} = page) do
    Repo.delete(page)
  end

  @doc """
  Deletes a page by node_id.
  """
  def delete_page_by_node_id(project_id, node_id) do
    case get_page_by_node_id(project_id, node_id) do
      nil -> {:error, :not_found}
      page -> delete_page(page)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page changes.
  """
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  # ============================================================================
  # Edges
  # ============================================================================

  @doc """
  Returns the list of edges for a project.
  """
  def list_edges(project_id) do
    Edge
    |> where([e], e.project_id == ^project_id)
    |> Repo.all()
  end

  @doc """
  Gets a single edge.
  """
  def get_edge!(id), do: Repo.get!(Edge, id)

  @doc """
  Gets an edge by project and edge_id.
  """
  def get_edge_by_edge_id(project_id, edge_id) do
    Repo.get_by(Edge, project_id: project_id, edge_id: edge_id)
  end

  @doc """
  Creates an edge (when nodes are connected).
  """
  def create_edge(project, attrs \\ %{}) do
    %Edge{}
    |> Edge.changeset(Map.put(attrs, "project_id", project.id))
    |> Repo.insert()
  end

  @doc """
  Deletes an edge.
  """
  def delete_edge(%Edge{} = edge) do
    Repo.delete(edge)
  end

  @doc """
  Deletes an edge by edge_id.
  """
  def delete_edge_by_edge_id(project_id, edge_id) do
    case get_edge_by_edge_id(project_id, edge_id) do
      nil -> {:error, :not_found}
      edge -> delete_edge(edge)
    end
  end

  # ============================================================================
  # Flow Data (for React Flow)
  # ============================================================================

  @doc """
  Gets all flow data for React Flow component.
  Returns nodes and edges in the format expected by React Flow.
  """
  def get_flow_data(project_id) do
    pages = list_pages(project_id)
    edges = list_edges(project_id)

    nodes =
      Enum.map(pages, fn page ->
        %{
          id: page.node_id,
          type: "page",
          position: %{x: page.position_x, y: page.position_y},
          data: %{
            label: page.name,
            slug: page.slug,
            page_id: page.id
          }
        }
      end)

    edges_data =
      Enum.map(edges, fn edge ->
        %{
          id: edge.edge_id,
          source: get_page!(edge.source_page_id).node_id,
          target: get_page!(edge.target_page_id).node_id,
          label: edge.label
        }
      end)

    %{nodes: nodes, edges: edges_data}
  end
end
