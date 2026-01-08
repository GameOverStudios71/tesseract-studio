defmodule TesseractStudioWeb.UserLive.Settings do
  use TesseractStudioWeb, :live_view

  on_mount {TesseractStudioWeb.UserAuth, :require_sudo_mode}

  alias TesseractStudio.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto space-y-8">
        <div class="text-center md:text-left">
          <.header class="border-b border-white/10 pb-6">
            <span class="text-2xl font-bold text-white">Account Settings</span>
            <:subtitle>
              <span class="text-white">
                Manage your account email address and password settings
              </span>
            </:subtitle>
          </.header>
        </div>

        <div class="glass-panel rounded-2xl !p-10 border border-white/5 bg-white/5 shadow-lg relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-gradient-to-b from-cyan-500/50 to-transparent opacity-50">
          </div>

          <h3 class="text-lg font-bold text-white !mb-6 flex items-center gap-3">
            <div class="w-8 h-8 rounded-lg bg-cyan-500/10 flex items-center justify-center">
              <i class="fa-solid fa-envelope text-cyan-400"></i>
            </div>
            Change Email
          </h3>

          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
            class="max-w-xl !space-y-6"
          >
            <.input
              field={@email_form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
              class="bg-black/20 border-white/10 focus:border-cyan-500/50 focus:ring-cyan-500/20 text-white placeholder-slate-600 rounded-none w-full !px-4 !py-3 !text-lg"
            />
            <.button
              class="st-btn !bg-none !bg-cyan-600/10 hover:!bg-cyan-600/20 border-cyan-500/50 text-cyan-100 shadow-none hover:!shadow-[0_6px_12px_rgba(6,182,212,0.3)] rounded-none backdrop-blur-md"
              phx-disable-with="Changing..."
            >
              Change Email
            </.button>
          </.form>
        </div>

        <div class="glass-panel rounded-2xl !p-10 border border-white/5 bg-white/5 shadow-lg relative overflow-hidden">
          <div class="absolute top-0 left-0 w-1 h-full bg-gradient-to-b from-purple-500/50 to-transparent opacity-50">
          </div>

          <h3 class="text-lg font-bold text-white !mb-6 flex items-center gap-3">
            <div class="w-8 h-8 rounded-lg bg-purple-500/10 flex items-center justify-center">
              <i class="fa-solid fa-lock text-purple-400"></i>
            </div>
            Change Password
          </h3>

          <.form
            for={@password_form}
            id="password_form"
            action={~p"/users/update-password"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            class="max-w-xl !space-y-6"
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              autocomplete="username"
              value={@current_email}
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label="New password"
              autocomplete="new-password"
              required
              class="bg-black/20 border-white/10 focus:border-purple-500/50 focus:ring-purple-500/20 text-white placeholder-slate-600 rounded-none w-full !px-4 !py-3 !text-lg"
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              autocomplete="new-password"
              class="bg-black/20 border-white/10 focus:border-purple-500/50 focus:ring-purple-500/20 text-white placeholder-slate-600 rounded-none w-full !px-4 !py-3 !text-lg"
            />
            <.button
              class="st-btn !bg-none !bg-purple-600/10 hover:!bg-purple-600/20 border-purple-500/50 text-purple-100 shadow-none hover:!shadow-[0_6px_12px_rgba(147,51,234,0.3)] rounded-none backdrop-blur-md"
              phx-disable-with="Saving..."
            >
              Save Password
            </.button>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, assign(socket, :active_tab, :settings)}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      changeset ->
        {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
    end
  end
end
