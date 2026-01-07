defmodule TesseractStudioWeb.PageController do
  use TesseractStudioWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
