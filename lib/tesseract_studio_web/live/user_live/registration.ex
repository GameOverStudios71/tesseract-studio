defmodule TesseractStudioWeb.UserLive.Registration do
  use TesseractStudioWeb, :live_view

  alias TesseractStudio.Accounts
  alias TesseractStudio.Accounts.User

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
                Register
              </span>
              <:subtitle>
                <p class="text-white mt-2">
                  Already registered?
                  <.link
                    navigate={~p"/users/log-in"}
                    class="font-semibold text-cyan-400 hover:text-cyan-300 hover:underline"
                  >
                    Log in
                  </.link>
                  to your account now.
                </p>
              </:subtitle>
            </.header>
          </div>

          <div class="!space-y-6">
            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              class="!space-y-6"
            >
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
                phx-mounted={JS.focus()}
                class="bg-black/20 border-white/10 focus:border-cyan-500/50 focus:ring-cyan-500/20 text-white placeholder-slate-600 rounded-none w-full !px-4 !py-3 !text-lg"
              />

              <.button
                phx-disable-with="Creating account..."
                class="st-btn w-full !bg-none !bg-cyan-600/10 hover:!bg-cyan-600/20 border-cyan-500/50 text-cyan-100 shadow-none hover:!shadow-[0_6px_12px_rgba(6,182,212,0.3)] rounded-none backdrop-blur-md"
              >
                Create an account <span aria-hidden="true">→</span>
              </.button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: TesseractStudioWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
