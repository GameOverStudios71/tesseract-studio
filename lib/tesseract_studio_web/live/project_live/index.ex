defmodule TesseractStudioWeb.ProjectLive.Index do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Studio
  alias TesseractStudio.Studio.Project

  @impl true
  def mount(_params, _session, socket) do
    projects = Studio.list_projects(socket.assigns.current_scope.user.id)

    {:ok,
     socket
     |> assign(:projects, projects)
     |> assign(:page_title, "My Projects")
     |> assign(:header_title, "My Projects")
     |> assign(:header_subtitle, "Build systems visually with nodes")
     |> assign(:header_actions, header_actions(%{}))
     |> assign(:show_modal, false)
     |> assign(:changeset, Studio.change_project(%Project{}))}
  end

  defp header_actions(assigns) do
    ~H"""
    <button phx-click="new_project" class="st-btn st-btn-premium st-btn-small whitespace-nowrap">
      + New Project
    </button>
    """
  end

  @impl true
  def handle_event("new_project", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      %Project{}
      |> Studio.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"project" => project_params}, socket) do
    case Studio.create_project(socket.assigns.current_scope.user, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully!")
         |> push_navigate(to: ~p"/projects/#{project.id}/builder")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("delete_project", %{"id" => id}, socket) do
    project = Studio.get_project!(id)

    case Studio.delete_project(project) do
      {:ok, _} ->
        projects = Studio.list_projects(socket.assigns.current_scope.user.id)

        {:noreply,
         socket
         |> put_flash(:info, "Project deleted")
         |> assign(:projects, projects)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete project")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= if @projects == [] do %>
          <div class="col-span-full st-card st-card-cyan text-center py-20">
            <div class="text-6xl mb-4 opacity-50">🧊</div>
            <h3 class="text-xl font-semibold text-white mb-2">No projects yet</h3>
            <p class="text-slate-400 mb-6">Create your first project to get started</p>
            <button phx-click="new_project" class="st-btn st-btn-cyan">
              <span>+</span> Create Project
            </button>
          </div>
        <% else %>
          <%= for project <- @projects do %>
            <.link navigate={~p"/projects/#{project.id}"} class="st-project-card group block">
              <div class="flex justify-between items-start w-full mb-2">
                <h3 class="st-project-card-title group-hover:text-cyan-400 transition-colors">
                  {project.name}
                </h3>
                <span class="st-badge st-badge-cyan text-[10px] font-mono">
                  /{project.slug}
                </span>
              </div>

              <p class="text-slate-400 text-sm line-clamp-2 min-h-[3em] mb-4">
                {project.description || "No description provided."}
              </p>
              
    <!-- Project Stats -->
              <div class="flex items-center justify-between text-xs text-slate-500 mb-4">
                <div class="flex items-center gap-4">
                  <span class="flex items-center gap-1">
                    <i class="fa-solid fa-file-lines"></i>
                    {length(project.pages)} pages
                  </span>
                </div>
                <span class="text-slate-600">
                  Updated {Calendar.strftime(project.updated_at, "%b %d, %Y")}
                </span>
              </div>

              <div class="flex gap-3 w-full justify-end items-center">
                <button
                  class="st-btn-icon-delete"
                  phx-click="delete_project"
                  phx-value-id={project.id}
                  data-confirm="Are you sure you want to delete this project?"
                  aria-label="Delete"
                  onclick="event.preventDefault(); event.stopPropagation();"
                >
                  <i class="fa-solid fa-trash"></i>
                </button>
              </div>
            </.link>
          <% end %>
        <% end %>
      </div>
    </div>

    <.modal :if={@show_modal} id="new-project-modal" show={true} on_cancel={JS.push("close_modal")}>
      <:title>New Project</:title>
      <.simple_form for={@changeset} phx-change="validate" phx-submit="save">
        <.input field={@changeset[:name]} label="Project Name" placeholder="My Awesome Project" />
        <.input
          field={@changeset[:description]}
          type="textarea"
          label="Description (optional)"
          placeholder="Describe your project..."
        />

        <:actions>
          <.button type="button" class="btn-ghost" phx-click="close_modal">Cancel</.button>
          <.button type="submit">Create Project</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end
end
