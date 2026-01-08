defmodule TesseractStudioWeb.PageLive.Show do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Studio

  @impl true
  def mount(params, _session, socket) do
    project_slug = params["project_slug"]
    page_slug = params["page_slug"] || "/"
    case Studio.get_project_by_slug!(project_slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Project not found")
         |> push_navigate(to: ~p"/")}

      project ->
        case Studio.get_page_by_slug(project.id, page_slug) do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "Page not found")
             |> push_navigate(to: ~p"/")}

          page ->
            # TesseractStudioWeb.UserAuth.mount_current_scope assigns :current_scope
            current_scope = socket.assigns[:current_scope]
            user = current_scope && current_scope.user

            can_edit = user && user.id == project.user_id

            {:ok,
             socket
             |> assign(:project, project)
             |> assign(:page, page)
             # Explicitly assign for render
             |> assign(:current_user, user)
             |> assign(:can_edit, can_edit)
             |> assign(:preview_mode, false)
             |> assign(:device_mode, "desktop")
             |> assign(:page_title, "#{page.name} - #{project.name}")}
        end
    end
  rescue
    Ecto.NoResultsError ->
      {:ok,
       socket
       |> put_flash(:error, "Project not found")
       |> push_navigate(to: ~p"/")}
  end

  @impl true
  def handle_event("toggle_preview", _params, socket) do
    {:noreply, assign(socket, :preview_mode, !socket.assigns.preview_mode)}
  end

  @impl true
  def handle_event("set_device_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :device_mode, mode)}
  end

  @impl true
  def handle_event("save_content", %{"content" => content}, socket) do
    if socket.assigns.can_edit do
      case Studio.update_page_content(socket.assigns.page, content) do
        {:ok, updated_page} ->
          {:noreply, assign(socket, :page, updated_page)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to save content")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="ts-page-container">
      <%= if @can_edit do %>
        <header class="ts-page-header">
          <div
            class="header-content"
            style="display: flex; justify-content: space-between; align-items: center;"
          >
            <div class="left-section">
              <div class="ts-page-breadcrumb">
                <span class="project-name">{@project.name}</span>
                <span class="separator">/</span>
                <span class="page-name">{@page.name}</span>
              </div>
              <div class="ts-page-meta">
                <span class="page-slug">/{@project.slug}/{@page.slug}</span>
              </div>
            </div>

            <div class="right-section" style="display: flex; gap: 10px; align-items: center;">
              <!-- Device Switcher -->
              <div
                class="device-switcher"
                style="display: flex; background: #334155; border-radius: 6px; overflow: hidden;"
              >
                <button
                  phx-click="set_device_mode"
                  phx-value-mode="desktop"
                  class={"device-btn #{if @device_mode == "desktop", do: "active"}"}
                  style={"padding: 6px 10px; border: none; background: #{if @device_mode == "desktop", do: "#3b82f6", else: "transparent"}; color: white; cursor: pointer;"}
                  title="Desktop"
                >
                  🖥️
                </button>
                <button
                  phx-click="set_device_mode"
                  phx-value-mode="tablet"
                  class={"device-btn #{if @device_mode == "tablet", do: "active"}"}
                  style={"padding: 6px 10px; border: none; background: #{if @device_mode == "tablet", do: "#3b82f6", else: "transparent"}; color: white; cursor: pointer;"}
                  title="Tablet"
                >
                  📱
                </button>
                <button
                  phx-click="set_device_mode"
                  phx-value-mode="mobile"
                  class={"device-btn #{if @device_mode == "mobile", do: "active"}"}
                  style={"padding: 6px 10px; border: none; background: #{if @device_mode == "mobile", do: "#3b82f6", else: "transparent"}; color: white; cursor: pointer;"}
                  title="Mobile"
                >
                  📱
                </button>
              </div>
              
    <!-- Preview Toggle -->
              <button
                phx-click="toggle_preview"
                class="ts-btn-secondary"
                style="padding: 6px 12px; border-radius: 6px; background: #475569; color: white; border: 1px solid #64748b; cursor: pointer;"
              >
                {if @preview_mode, do: "✏️ Edit Check", else: "👁️ Preview"}
              </button>
            </div>
          </div>
        </header>
      <% end %>

      <main class="ts-page-content">
        <div class={"ts-editor-device-frame is-#{@device_mode}"}>
          <div
            id="content-editor-container"
            phx-hook="ContentEditor"
            phx-update="ignore"
            data-content={Jason.encode!(@page.content || %{})}
            data-editable={"#{@can_edit && !@preview_mode}"}
            class="ts-content-editor-wrapper"
          >
            <!-- React Editor Mount Point -->
          </div>
        </div>
      </main>
    </div>
    """
  end
end
