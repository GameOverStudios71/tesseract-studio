defmodule TesseractStudioWeb.UserLive.Login do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-[80vh] items-center justify-center">
        <div class="glass-panel w-full max-w-md !p-10 !space-y-8 border border-white/5 bg-white/5 shadow-2xl relative overflow-hidden rounded-2xl">
          <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-cyan-500/50 to-transparent opacity-50">
          </div>

          <div class="text-center">
            <.header class="text-left">
              <span class="text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white to-slate-400">
                Log in
              </span>
              <:subtitle>
                <%= if @current_scope do %>
                  <p class="text-white mt-2">
                    You need to reauthenticate to perform sensitive actions.
                  </p>
                <% else %>
                  <p class="text-white mt-2">
                    Don't have an account?
                    <.link
                      navigate={~p"/users/register"}
                      class="font-semibold text-cyan-400 hover:text-cyan-300 hover:underline"
                    >
                      Sign up
                    </.link>
                    for an account.
                  </p>
                <% end %>
              </:subtitle>
            </.header>
          </div>

          <div
            :if={local_mail_adapter?()}
            class="flex items-center justify-center gap-4 p-5 bg-cyan-500/10 border border-cyan-500 backdrop-blur-md text-sm text-white rounded-none"
          >
            <.icon name="hero-information-circle" class="size-5 shrink-0 text-cyan-400 mt-0.5" />
            <div class="space-y-1">
              <p class="font-medium text-cyan-400">Local Mail Adapter</p>
              <p>
                You are running the local mail adapter. To see sent emails, visit <.link
                  href="/dev/mailbox"
                  class="underline hover:text-white"
                >the mailbox page</.link>.
              </p>
            </div>
          </div>

          <div class="!space-y-6">
            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log-in"}
              phx-submit="submit_magic"
              class="!space-y-4"
            >
              <div>
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label="Email"
                  autocomplete="email"
                  required
                  phx-mounted={JS.focus()}
                  class="bg-black/20 border-white/10 focus:border-cyan-500/50 focus:ring-cyan-500/20 text-white placeholder-slate-600 rounded-none w-full !px-4 !py-3 !text-lg"
                />
              </div>
              <.button class="st-btn w-full !bg-none !bg-cyan-600/10 hover:!bg-cyan-600/20 border-cyan-500/50 text-cyan-100 shadow-none hover:!shadow-[0_6px_12px_rgba(6,182,212,0.3)] rounded-none backdrop-blur-md">
                Log in with email <span aria-hidden="true">→</span>
              </.button>
            </.form>

            <div class="flex items-center gap-4 py-2">
              <div class="h-px bg-white flex-1"></div>
              <span class="text-white/70 text-sm">or use password</span>
              <div class="h-px bg-white flex-1"></div>
            </div>

            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="!space-y-4"
            >
              <div class="hidden">
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  label="Email"
                  autocomplete="email"
                  required
                />
              </div>
              <div>
                <.input
                  field={@form[:password]}
                  type="password"
                  label="Password"
                  autocomplete="current-password"
                  class="bg-black/20 border-white/10 focus:border-cyan-500/50 focus:ring-cyan-500/20 text-white placeholder-slate-600 rounded-none w-full !px-4 !py-3 !text-lg"
                />
              </div>

              <div class="space-y-3 pt-2">
                <.button
                  class="st-btn w-full !bg-none !bg-blue-600/10 hover:!bg-blue-600/20 border-indigo-500/50 text-indigo-100 shadow-none hover:!shadow-[0_6px_12px_rgba(79,70,229,0.3)] rounded-none backdrop-blur-md"
                  name={@form[:remember_me].name}
                  value="true"
                >
                  Log in and stay logged in <span aria-hidden="true">→</span>
                </.button>
                <.button class="btn btn-ghost w-full text-white hover:text-white hover:bg-white/5 rounded-none">
                  Log in only this time
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:tesseract_studio, TesseractStudio.Mailer)[:adapter] ==
      Swoosh.Adapters.Local
  end
end
