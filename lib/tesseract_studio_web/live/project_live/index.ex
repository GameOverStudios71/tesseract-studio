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
    <.button phx-click="new_project" class="shadow-lg shadow-blue-500/20 whitespace-nowrap">
      + New Project
    </.button>
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
          <div class="col-span-full text-center py-20 bg-slate-800/50 rounded-2xl border border-slate-700 border-dashed">
            <div class="text-6xl mb-4">🧊</div>
            <h3 class="text-xl font-semibold text-white">No projects yet</h3>
            <p class="text-slate-400 mb-6">Create your first project to get started</p>
            <.button phx-click="new_project">
              Create Project
            </.button>
          </div>
        <% else %>
          <%= for project <- @projects do %>
            <.card class="bg-slate-800 border-slate-700 hover:border-blue-500/50 transition-colors group hover:shadow-xl hover:shadow-blue-900/10">
              <:header>
                <div class="flex justify-between items-start w-full">
                  <h3 class="text-xl font-bold text-white group-hover:text-blue-400 transition-colors">
                    {project.name}
                  </h3>
                  <span class="text-xs font-mono text-slate-500 bg-slate-900 px-2 py-1 rounded">
                    /{project.slug}
                  </span>
                </div>
              </:header>

              <p class="text-slate-400 text-sm line-clamp-3 min-h-[4.5em]">
                {project.description || "No description provided."}
              </p>

              <:footer>
                <div class="flex gap-2 w-full justify-between items-center">
                  <.button navigate={~p"/projects/#{project.id}/builder"} class="btn-sm btn-outline">
                    Open Builder
                  </.button>
                  <button
                    class="btn btn-ghost btn-sm btn-circle text-error hover:bg-error/10"
                    phx-click="delete_project"
                    phx-value-id={project.id}
                    data-confirm="Are you sure you want to delete this project?"
                    aria-label="Delete"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </button>
                </div>
              </:footer>
            </.card>
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
