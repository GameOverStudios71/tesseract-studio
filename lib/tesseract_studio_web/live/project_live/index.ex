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
     |> assign(:project_to_delete, nil)
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
  @impl true
  def handle_event("confirm_delete_project", %{"id" => id}, socket) do
    project = Studio.get_project!(id)
    {:noreply, assign(socket, :project_to_delete, project)}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :project_to_delete, nil)}
  end

  @impl true
  def handle_event("do_delete_project", _params, socket) do
    project = socket.assigns.project_to_delete

    case Studio.delete_project(project) do
      {:ok, _} ->
        projects = Studio.list_projects(socket.assigns.current_scope.user.id)

        {:noreply,
         socket
         |> put_flash(:info, "Project deleted successfully")
         |> assign(:projects, projects)
         |> assign(:project_to_delete, nil)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not delete project")
         |> assign(:project_to_delete, nil)}
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
            <div class="st-project-card group flex flex-col relative">
              <.link navigate={~p"/projects/#{project.id}"} class="absolute inset-0 z-10 rounded-xl">
                <span class="sr-only">View {project.name}</span>
              </.link>

              <div class="relative z-0 pointer-events-none">
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
                  <span class="text-slate-400">
                    Updated {Calendar.strftime(project.updated_at, "%b %d, %Y")}
                  </span>
                </div>
              </div>

              <div class="flex gap-3 w-full justify-end items-center mt-auto pt-4 border-t border-white/5 relative z-20 pointer-events-auto">
                <button
                  class="st-btn-icon-delete cursor-pointer"
                  phx-click="confirm_delete_project"
                  phx-value-id={project.id}
                  aria-label="Delete"
                >
                  <i class="fa-solid fa-trash"></i>
                </button>
              </div>
            </div>
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

    <.modal
      :if={@project_to_delete}
      id="delete-project-modal"
      show={true}
      on_cancel={JS.push("cancel_delete")}
      variant={:danger}
    >
      <:title>Delete Project</:title>
      <div class="mb-8 mt-4" style="margin-top: 2rem; margin-bottom: 2rem; padding: 0;">
        <div
          class="flex items-center gap-5 border-y border-red-500/20 bg-red-500/5 backdrop-blur-md"
          style="margin: 0 -40px 1.5rem -40px; padding: 1.5rem 40px; gap: 1.25rem; border-left: none; border-right: none;"
        >
          <div
            class="flex items-center justify-center shrink-0"
            style="width: 4rem; height: 4rem;"
          >
            <i
              class="fa-solid fa-triangle-exclamation text-red-500"
              style="font-size: 3rem; filter: drop-shadow(0 0 10px rgba(239, 68, 68, 0.5));"
            >
            </i>
          </div>
          <div>
            <p
              class="text-white font-bold text-lg mb-1 tracking-tight uppercase"
              style="margin-bottom: 0.25rem; font-size: 1.125rem;"
            >
              Are you sure?
            </p>
            <p class="text-slate-300 text-sm">
              You are about to delete <span class="text-white font-bold">{@project_to_delete.name}</span>.
            </p>
          </div>
        </div>
        <p
          class="text-slate-400 text-sm leading-relaxed px-1"
          style="padding-left: 0.25rem; padding-right: 0.25rem; line-height: 1.6;"
        >
          This action is permanent and cannot be undone. All pages, flows, and configurations associated with this project will be lost forever.
        </p>
      </div>
      <div class="flex justify-end gap-3">
        <button
          class="st-btn rounded-full border border-white/10 bg-white/5 hover:bg-white/10 backdrop-blur-md text-slate-300 hover:text-white transition-all shadow-none hover:shadow-none"
          style="background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1);"
          phx-click="cancel_delete"
        >
          Cancel
        </button>
        <button
          class="st-btn rounded-full border border-red-500/20 bg-red-500/10 hover:bg-red-500/20 backdrop-blur-md text-red-400 hover:text-red-300 transition-all shadow-none hover:shadow-none"
          style="background: rgba(239, 68, 68, 0.1); border: 1px solid rgba(239, 68, 68, 0.2);"
          phx-click="do_delete_project"
        >
          <i class="fa-solid fa-trash mr-2"></i> Delete Project
        </button>
      </div>
    </.modal>
    """
  end
end
