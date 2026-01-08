defmodule TesseractStudioWeb.FlowLive do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Studio

  @impl true
  def mount(%{"id" => project_id}, _session, socket) do
    project = Studio.get_project!(project_id)

    if project.user_id != socket.assigns.current_scope.user.id do
      {:ok,
       socket
       |> put_flash(:error, "You don't have access to this project")
       |> push_navigate(to: ~p"/projects")}
    else
      # Fetch only flow data (nodes of type :flow)
      flow_data = Studio.get_flow_data(project.id, :flow)

      {:ok,
       socket
       |> assign(:active_tab, :flow)
       |> assign(:project, project)
       |> assign(:page_title, "#{project.name} - Flow Design")
       |> assign(:header_title, project.name)
       |> assign(:header_subtitle, "/#{project.slug}")
       |> assign(:header_actions, header_actions(%{}))
       |> assign(:nodes, flow_data.nodes)
       |> assign(:edges, flow_data.edges)
       |> assign(:delete_data, nil)}
    end
  end

  @impl true
  def handle_event("add_node", _params, socket) do
    project = socket.assigns.project
    # Default naming logic for nodes
    node_count = length(socket.assigns.nodes) + 1
    attrs = %{
      "name" => "Node #{node_count}",
      "node_id" => "node-#{System.unique_integer([:positive])}",
      "position_x" => 150.0 + :rand.uniform(300),
      "position_y" => 150.0 + :rand.uniform(300)
    }

    case Studio.create_flow(project, attrs) do
      {:ok, _flow} ->
        flow_data = Studio.get_flow_data(project.id, :flow)
        {:noreply, socket |> assign(:nodes, flow_data.nodes) |> assign(:edges, flow_data.edges) |> push_event("update_flow", flow_data)}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create node")}
    end
  end

  @impl true
  def handle_event("request_delete_page", %{"node_id" => node_id}, socket) do
    # "page" here comes from the generic React event 'request_delete_page', needs to be unified in React eventually
    project = socket.assigns.project
    if flow = Studio.get_flow_by_node_id(project.id, node_id) do
      {:noreply, assign(socket, :delete_data, %{type: :flow, id: node_id, name: flow.name})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :delete_data, nil)}
  end

  @impl true
  def handle_event("do_delete_item", _params, socket) do
    %{type: :flow, id: node_id} = socket.assigns.delete_data
    project = socket.assigns.project

    case Studio.delete_flow_by_node_id(project.id, node_id) do
      {:ok, _} ->
        flow_data = Studio.get_flow_data(project.id, :flow)
        {:noreply, 
          socket 
          |> assign(:nodes, flow_data.nodes) 
          |> assign(:edges, flow_data.edges) 
          |> assign(:delete_data, nil)
          |> push_event("update_flow", flow_data)}
      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Failed to delete node") |> assign(:delete_data, nil)}
    end
  end

  @impl true
  def handle_event("move_page", %{"node_id" => node_id, "x" => x, "y" => y}, socket) do
    # Renaming event on React side is expensive now, so we map "move_page" to Studio.update_flow_position
    project = socket.assigns.project
    if flow = Studio.get_flow_by_node_id(project.id, node_id) do
      Studio.update_flow_position(flow, x, y)
    end
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_edge", %{"id" => edge_id, "source" => src_id, "target" => tgt_id}, socket) do
    # Edges currently shared or mocked. For now we just don't save edges for Flows until we have a FlowsEdge table
    # OR we reuse the Edge table but that links 'pages'.
    # Since avoiding page table pollution is the goal, for NOW we will NOT persist edges for flows 
    # to avoid FK errors (since Edge references Page ID).
    # TODO: Create FlowEdge table.
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_edge", %{"edge_id" => edge_id}, socket) do
     # TODO: FlowEdge logic
    {:noreply, socket}
  end

  defp header_actions(assigns) do
    ~H"""
    <button phx-click="add_node" class="st-btn st-btn-premium st-btn-small whitespace-nowrap">
      <i class="fa-solid fa-plus mr-2"></i> Add Node
    </button>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="ts-builder-wrapper">
      <div
        id="react-flow-container-flow"
        phx-hook="ReactFlow"
        phx-update="ignore"
        data-nodes={Jason.encode!(@nodes)}
        data-edges={Jason.encode!(@edges)}
        data-project-slug={@project.slug}
        class="ts-flow-container"
      >
      </div>

      <.delete_confirmation_modal
        :if={@delete_data}
        id="delete-node-modal"
        show={true}
        on_cancel={JS.push("cancel_delete")}
        on_confirm={JS.push("do_delete_item")}
        title="Delete Node"
        item_name={@delete_data.name}
        message="This action is permanent and cannot be undone."
        confirm_label="Delete Node"
      />
    </div>
    """
  end
end
