defmodule TesseractStudioWeb.ProjectLive.Show do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Studio

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    project = Studio.get_project!(id)

    {:ok,
     socket
     |> assign(:project, project)
     |> assign(:page_title, project.name)
     |> assign(:header_title, project.name)
     |> assign(:header_subtitle, "/#{project.slug}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Flow Design Card -->
        <.link
          navigate={~p"/projects/#{@project.id}/flow"}
          class="st-card st-card-interactive st-card-cyan p-8 text-center block"
        >
          <div class="text-5xl mb-4">
            <i class="fa-solid fa-diagram-project text-cyan-400"></i>
          </div>
          <h2 class="text-2xl font-bold text-white mb-2">Flow Design</h2>
          <p class="text-slate-400">
            Design the visual flow of your system with nodes and connections
          </p>
        </.link>
        
    <!-- System Builder Card -->
        <.link
          navigate={~p"/projects/#{@project.id}/builder"}
          class="st-card st-card-interactive st-card-purple p-8 text-center block"
        >
          <div class="text-5xl mb-4">
            <i class="fa-solid fa-cubes text-purple-400"></i>
          </div>
          <h2 class="text-2xl font-bold text-white mb-2">System Builder</h2>
          <p class="text-slate-400">
            Build and configure nodes, pages and components
          </p>
        </.link>
      </div>
    </div>
    """
  end
end
