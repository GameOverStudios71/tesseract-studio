defmodule TesseractStudioWeb.HomeLive do
  use TesseractStudioWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Welcome")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    """
  end
end
