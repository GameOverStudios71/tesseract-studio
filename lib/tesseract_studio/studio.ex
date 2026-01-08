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
    |> preload(:pages)
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
    result =
      %Project{}
      |> Project.changeset(Map.put(attrs, "user_id", user.id))
      |> Repo.insert()

    case result do
      {:ok, project} ->
        # Create default Home page
        create_page(project, %{
          "name" => "Home",
          "slug" => "/",
          "node_id" => "node-home-#{Ecto.UUID.generate()}",
          "position_x" => 250,
          "position_y" => 250,
          "content" => %{"type" => "doc", "content" => []}
        })

        {:ok, project}

      error ->
        error
    end
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
      # Prevent deleting home page (root)
      %Page{slug: "/"} -> {:error, :forbidden}
      %Page{slug: "home"} -> {:error, :forbidden}
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
  # Flows
  # ============================================================================

  alias TesseractStudio.Studio.Flow

  @doc """
  Returns the list of flows for a project.
  """
  def list_flows(project_id) do
    Flow
    |> where([f], f.project_id == ^project_id)
    |> order_by([f], asc: f.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single flow.
  """
  def get_flow!(id), do: Repo.get!(Flow, id)

  @doc """
  Gets a flow by project and node_id.
  """
  def get_flow_by_node_id(project_id, node_id) do
    Repo.get_by(Flow, project_id: project_id, node_id: node_id)
  end

  @doc """
  Creates a flow.
  """
  def create_flow(project, attrs \\ %{}) do
    %Flow{}
    |> Flow.changeset(Map.put(attrs, "project_id", project.id))
    |> Repo.insert()
  end

  @doc """
  Updates a flow position.
  """
  def update_flow_position(%Flow{} = flow, x, y) do
    flow
    |> Flow.position_changeset(%{position_x: x, position_y: y})
    |> Repo.update()
  end

  @doc """
  Deletes a flow.
  """
  def delete_flow(%Flow{} = flow) do
    Repo.delete(flow)
  end

  @doc """
  Deletes a flow by node_id.
  """
  def delete_flow_by_node_id(project_id, node_id) do
    case get_flow_by_node_id(project_id, node_id) do
      nil -> {:error, :not_found}
      flow -> delete_flow(flow)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking flow changes.
  """
  def change_flow(%Flow{} = flow, attrs \\ %{}) do
    Flow.changeset(flow, attrs)
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
  Optionally filters by type :page or :flow, default :all.
  """
  def get_flow_data(project_id, type \\ :all) do
    pages = if type in [:all, :page], do: list_pages(project_id), else: []
    flows = if type in [:all, :flow], do: list_flows(project_id), else: []
    # Shared edges for now, though eventually flows might need their own edges table
    edges = list_edges(project_id) 

    page_nodes =
      Enum.map(pages, fn page ->
        %{
          id: page.node_id,
          type: "page",
          position: %{x: page.position_x, y: page.position_y},
          data: %{
            label: page.name,
            slug: page.slug,
            page_id: page.id,
            is_root: page.slug in ["/", "home"]
          }
        }
      end)

    flow_nodes =
      Enum.map(flows, fn flow ->
        %{
          id: flow.node_id,
          type: "flow", # Custom node type for frontend
          position: %{x: flow.position_x, y: flow.position_y},
          data: %{
            label: flow.name,
            flow_id: flow.id
          }
        }
      end)

    edges_data =
      Enum.map(edges, fn edge ->
        # Ideally we check if source/target exist, but for now assuming integrity
        %{
          id: edge.edge_id,
          source: get_node_id_from_edge(edge.source_page_id),
          target: get_node_id_from_edge(edge.target_page_id),
          label: edge.label
        }
      end)

    %{nodes: page_nodes ++ flow_nodes, edges: edges_data}
  end

  # Helper to resolve node_id from internal IDs - simple version for now
  # In a real scenario, edges would probably be polymorphic or separate tables
  defp get_node_id_from_edge(page_id) do
    # This is legacy edge support for Pages only currently
    # Flow edges would need separate logic
    Repo.get!(Page, page_id).node_id
  end
end
