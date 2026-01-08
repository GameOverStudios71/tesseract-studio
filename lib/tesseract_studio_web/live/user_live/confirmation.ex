defmodule TesseractStudioWeb.UserLive.Confirmation do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-[80vh] items-center justify-center">
        <div class="glass-panel w-full max-w-sm !p-10 rounded-2xl !space-y-6 border border-white/5 bg-white/5 shadow-2xl relative overflow-hidden">
          <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-cyan-500/50 to-transparent opacity-50">
          </div>

          <div class="text-center">
            <.header class="text-left">
              <span class="text-xl font-bold text-white">Welcome {@user.email}</span>
            </.header>
          </div>

          <div class="space-y-4">
            <.form
              :if={!@user.confirmed_at}
              for={@form}
              id="confirmation_form"
              phx-mounted={JS.focus_first()}
              phx-submit="submit"
              action={~p"/users/log-in?_action=confirmed"}
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
              <.button
                name={@form[:remember_me].name}
                value="true"
                phx-disable-with="Confirming..."
                class="st-btn w-full !bg-none !bg-cyan-600/10 hover:!bg-cyan-600/20 border-cyan-500/50 text-cyan-100 shadow-none hover:!shadow-[0_6px_12px_rgba(6,182,212,0.3)] rounded-none backdrop-blur-md"
              >
                Confirm and stay logged in
              </.button>
              <.button
                phx-disable-with="Confirming..."
                class="btn btn-ghost w-full text-white hover:text-white hover:bg-white/5 rounded-none"
              >
                Confirm and log in only this time
              </.button>
            </.form>

            <.form
              :if={@user.confirmed_at}
              for={@form}
              id="login_form"
              phx-submit="submit"
              phx-mounted={JS.focus_first()}
              action={~p"/users/log-in"}
              phx-trigger-action={@trigger_submit}
              class="space-y-4"
            >
              <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
              <%= if @current_scope do %>
                <.button
                  phx-disable-with="Logging in..."
                  class="st-btn w-full !bg-none !bg-cyan-600/10 hover:!bg-cyan-600/20 border-cyan-500/50 text-cyan-100 shadow-none hover:!shadow-[0_6px_12px_rgba(6,182,212,0.3)] rounded-none backdrop-blur-md"
                >
                  Log in
                </.button>
              <% else %>
                <.button
                  name={@form[:remember_me].name}
                  value="true"
                  phx-disable-with="Logging in..."
                  class="st-btn w-full !bg-none !bg-cyan-600/10 hover:!bg-cyan-600/20 border-cyan-500/50 text-cyan-100 shadow-none hover:!shadow-[0_6px_12px_rgba(6,182,212,0.3)] rounded-none backdrop-blur-md"
                >
                  Keep me logged in on this device
                </.button>
                <.button
                  phx-disable-with="Logging in..."
                  class="btn btn-ghost w-full text-white hover:text-white hover:bg-white/5 rounded-none"
                >
                  Log me in only this time
                </.button>
              <% end %>
            </.form>

            <p
              :if={!@user.confirmed_at}
              class="flex items-center justify-center gap-3 p-5 bg-white/5 border border-white/20 backdrop-blur-md text-sm text-white rounded-none"
            >
              <i class="fa-solid fa-lightbulb text-yellow-500/80"></i>
              Tip: If you prefer passwords, you can enable them in the user settings.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
