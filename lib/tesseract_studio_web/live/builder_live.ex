defmodule TesseractStudioWeb.BuilderLive do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Studio

  @impl true
  def mount(%{"id" => project_id}, _session, socket) do
    project = Studio.get_project!(project_id)

    # Verify the project belongs to the current user
    if project.user_id != socket.assigns.current_scope.user.id do
      {:ok,
       socket
       |> put_flash(:error, "You don't have access to this project")
       |> push_navigate(to: ~p"/projects")}
    else
      flow_data = Studio.get_flow_data(project.id)

      {:ok,
       socket
       |> assign(:project, project)
       |> assign(:page_title, "#{project.name} - Builder")
       |> assign(:header_title, project.name)
       |> assign(:header_subtitle, "/#{project.slug}")
       |> assign(:header_actions, header_actions(%{}))
       |> assign(:nodes, flow_data.nodes)
       |> assign(:edges, flow_data.edges)}
    end
  end

  @impl true
  def handle_event("add_page", params, socket) do
    project = socket.assigns.project

    attrs = %{
      "name" => params["name"] || "Page #{length(socket.assigns.nodes) + 1}",
      "slug" => params["slug"] || "page-#{length(socket.assigns.nodes) + 1}",
      "node_id" => params["node_id"] || "node-#{System.unique_integer([:positive])}",
      "position_x" => params["position_x"] || 150.0 + :rand.uniform(300),
      "position_y" => params["position_y"] || 150.0 + :rand.uniform(300)
    }

    case Studio.create_page(project, attrs) do
      {:ok, _page} ->
        # Refresh flow data
        flow_data = Studio.get_flow_data(project.id)

        {:noreply,
         socket
         |> assign(:nodes, flow_data.nodes)
         |> assign(:edges, flow_data.edges)
         |> push_event("update_flow", flow_data)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create page")}
    end
  end

  @impl true
  def handle_event("delete_page", %{"node_id" => node_id}, socket) do
    project = socket.assigns.project

    case Studio.delete_page_by_node_id(project.id, node_id) do
      {:ok, _} ->
        flow_data = Studio.get_flow_data(project.id)

        {:noreply,
         socket
         |> assign(:nodes, flow_data.nodes)
         |> assign(:edges, flow_data.edges)
         |> push_event("update_flow", flow_data)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move_page", %{"node_id" => node_id, "x" => x, "y" => y}, socket) do
    project = socket.assigns.project

    case Studio.get_page_by_node_id(project.id, node_id) do
      nil ->
        {:noreply, socket}

      page ->
        Studio.update_page_position(page, x, y)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "add_edge",
        %{"id" => edge_id, "source" => source_node_id, "target" => target_node_id},
        socket
      ) do
    project = socket.assigns.project

    source_page = Studio.get_page_by_node_id(project.id, source_node_id)
    target_page = Studio.get_page_by_node_id(project.id, target_node_id)

    if source_page && target_page do
      attrs = %{
        "edge_id" => edge_id,
        "source_page_id" => source_page.id,
        "target_page_id" => target_page.id
      }

      case Studio.create_edge(project, attrs) do
        {:ok, _edge} ->
          flow_data = Studio.get_flow_data(project.id)
          {:noreply, assign(socket, :edges, flow_data.edges)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_edge", %{"edge_id" => edge_id}, socket) do
    project = socket.assigns.project

    case Studio.delete_edge_by_edge_id(project.id, edge_id) do
      {:ok, _} ->
        flow_data = Studio.get_flow_data(project.id)
        {:noreply, assign(socket, :edges, flow_data.edges)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp header_actions(assigns) do
    ~H"""
    <button phx-click="add_page" class="st-btn st-btn-premium st-btn-small whitespace-nowrap">
      <i class="fa-solid fa-plus mr-2"></i> Add Page
    </button>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="ts-builder-wrapper">
      <div
        id="react-flow-container"
        phx-hook="ReactFlow"
        phx-update="ignore"
        data-nodes={Jason.encode!(@nodes)}
        data-edges={Jason.encode!(@edges)}
        data-project-slug={@project.slug}
        class="ts-flow-container"
      >
        <!-- React Flow will be mounted here -->
      </div>
    </div>
    """
  end
end
