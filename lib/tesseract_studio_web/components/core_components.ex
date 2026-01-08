defmodule TesseractStudioWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: TesseractStudioWeb.Gettext

  alias Phoenix.LiveView.JS

  use Phoenix.VerifiedRoutes,
    endpoint: TesseractStudioWeb.Endpoint,
    router: TesseractStudioWeb.Router,
    statics: TesseractStudioWeb.static_paths()

  @doc """
  Renders the application sidebar.
  """
  attr :active_tab, :atom, default: :projects
  attr :project, :any, default: nil

  def sidebar(assigns) do
    ~H"""
    <aside id="sidebar" class="st-sidebar collapsed">
      <div class="st-sidebar-header">
        <span class="st-sidebar-header-text">Menu</span>
        <button class="st-sidebar-toggle" onclick="document.getElementById('sidebar').classList.toggle('collapsed'); document.getElementById('main-content').classList.toggle('sidebar-collapsed');">
          <i class="fa-solid fa-chevron-left"></i>
        </button>
      </div>
      
      <nav class="st-sidebar-nav">
        <div class="st-sidebar-section">
          <.link
            navigate="/projects"
            class={["st-sidebar-item", (@active_tab in [:projects, :flow, :builder]) && "active"]}
          >
            <i class="st-sidebar-item-icon fa-solid fa-folder-open"></i>
            <span class="st-sidebar-item-text">Projects</span>
          </.link>
          
          <!-- Project Sub-items (shown when in project context) -->
          <%= if @project do %>
            <.link
              navigate={~p"/projects/#{@project.id}/flow"}
              class={["st-sidebar-subitem", (@active_tab == :flow) && "active"]}
            >
              <i class="st-sidebar-item-icon fa-solid fa-diagram-project"></i>
              <span class="st-sidebar-item-text">Flow Design</span>
            </.link>
            <.link
              navigate={~p"/projects/#{@project.id}/builder"}
              class={["st-sidebar-subitem", (@active_tab == :builder) && "active"]}
            >
              <i class="st-sidebar-item-icon fa-solid fa-cubes"></i>
              <span class="st-sidebar-item-text">System Builder</span>
            </.link>
          <% end %>
        </div>
      </nav>
      
      <!-- Settings at bottom -->
      <div class="st-sidebar-footer">
        <.link
          navigate="/users/settings"
          class={["st-sidebar-item", (@active_tab == :settings) && "active"]}
        >
          <i class="st-sidebar-item-icon fa-solid fa-gear"></i>
          <span class="st-sidebar-item-text">Settings</span>
        </.link>
      </div>
    </aside>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-bottom toast-end z-50 mb-12 mx-6"
      {@rest}
    >
      <div class={[
        "w-[400px] min-h-[80px] rounded-xl shadow-2xl backdrop-blur-xl border flex items-center transform transition-all duration-300 hover:scale-[1.02] ts-toast-content",
        @kind == :info &&
          "bg-cyan-500/10 text-cyan-50 border-cyan-500 shadow-cyan-500/20",
        @kind == :error && "bg-red-500/10 text-red-50 border-red-500 shadow-red-500/20"
      ]}>
        <.icon
          :if={@kind == :info}
          name="hero-information-circle-solid"
          class="size-6 shrink-0 text-cyan-400"
        />
        <.icon
          :if={@kind == :error}
          name="hero-exclamation-circle-solid"
          class="size-6 shrink-0 text-red-500"
        />
        <div class="flex-1 min-w-0 text-center">
          <p :if={@title} class="font-bold text-sm mb-1">{@title}</p>
          <p class="text-sm font-medium leading-relaxed opacity-90">{msg}</p>
        </div>
        <button
          type="button"
          class="group self-center cursor-pointer p-1"
          aria-label={gettext("close")}
        >
          <.icon
            name="hero-x-mark"
            class="size-4 opacity-50 group-hover:opacity-100 transition-opacity"
          />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-4">
      <label>
        <span :if={@label} class="label mb-2 text-slate-300 font-medium text-sm">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "w-full glass-input rounded-lg px-4 py-2.5 text-sm",
            @class,
            @errors != [] && "border-red-500 focus:border-red-500"
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <div class="mt-2 flex items-center justify-center gap-3 p-5 bg-red-500/10 border border-red-500 backdrop-blur-md rounded-none text-red-100 text-sm animate-pulse">
      <.icon name="hero-exclamation-circle-mini" class="size-5 shrink-0 text-red-500" />
      <span class="leading-relaxed">
        {render_slot(@inner_block)}
      </span>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(TesseractStudioWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(TesseractStudioWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a save button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-4">
        {render_slot(@inner_block, f)}
        <div :if={@actions != []} class="flex items-center justify-end gap-2 mt-4">
          {render_slot(@actions, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: %JS{}
  attr :variant, :atom, values: [:default, :danger], default: :default
  slot :inner_block, required: true
  slot :title
  slot :actions

  def modal(assigns) do
    assigns = assign_new(assigns, :variant, fn -> :default end)

    border_color =
      if assigns.variant == :danger,
        do: "rgba(239, 68, 68, 0.3)",
        else: "rgba(255, 255, 255, 0.08)"

    assigns = assign(assigns, :border_color, border_color)

    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center p-4 text-center sm:p-0">
          <div
            class="glass-panel-heavy w-full max-w-lg transform overflow-hidden rounded-2xl text-left align-middle transition-all"
            style={"padding: 40px; border-radius: 16px; background: rgba(20, 20, 20, 0.7); backdrop-filter: blur(40px) saturate(150%); -webkit-backdrop-filter: blur(40px) saturate(150%); border: 1px solid #{@border_color}; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);"}
          >
            <div class="mb-6" style="margin-bottom: 30px;">
              <h3
                :if={@title != []}
                id={"#{@id}-title"}
                class="text-lg font-bold leading-6"
                style="font-size: 1.5rem; font-weight: 700; color: white;"
              >
                {render_slot(@title)}
              </h3>
            </div>
            <button
              type="button"
              class="btn btn-ghost btn-sm btn-circle absolute"
              style="position: absolute; right: 32px; top: 32px;"
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
              aria-label={gettext("close")}
            >
              ✕
            </button>
            <div id={"#{@id}-content"}>
              {render_slot(@inner_block)}
            </div>
            <div
              :if={@actions != []}
              class="mt-8 flex justify-end gap-4"
              style="margin-top: 40px; display: flex; justify-content: flex-end; align-items: center; gap: 16px;"
            >
              {render_slot(@actions)}
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a standardized delete confirmation modal with premium "danger" styling.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :title, :string, default: "Are you sure?"
  attr :message, :string, required: true
  attr :item_name, :string, required: true
  attr :confirm_label, :string, default: "Delete"
  attr :on_cancel, :any, default: %JS{}
  attr :on_confirm, :any, required: true

  def delete_confirmation_modal(assigns) do
    ~H"""
    <.modal
      id={@id}
      show={@show}
      on_cancel={@on_cancel}
      variant={:danger}
    >
      <:title>{@title}</:title>
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
              {@title}
            </p>
            <p class="text-slate-300 text-sm">
              You are about to delete <span class="text-white font-bold">{@item_name}</span>.
            </p>
          </div>
        </div>
        <p
          class="text-slate-400 text-sm leading-relaxed px-1"
          style="padding-left: 0.25rem; padding-right: 0.25rem; line-height: 1.6;"
        >
          {@message}
        </p>
      </div>
      <div class="flex justify-end gap-3">
        <button
          class="st-btn rounded-full border border-white/10 bg-white/5 hover:bg-white/10 backdrop-blur-md text-slate-300 hover:text-white transition-all shadow-none hover:shadow-none !important"
          style="background: rgba(255, 255, 255, 0.05); border: 1px solid rgba(255, 255, 255, 0.1); box-shadow: none !important;"
          phx-click={@on_cancel}
        >
          Cancel
        </button>
        <button
          class="st-btn rounded-full border border-red-500/20 bg-red-500/10 hover:bg-red-500/20 backdrop-blur-md text-red-400 hover:text-red-300 transition-all shadow-none hover:shadow-none !important"
          style="background: rgba(239, 68, 68, 0.1); border: 1px solid rgba(239, 68, 68, 0.2); box-shadow: none !important;"
          phx-click={@on_confirm}
        >
          <i class="fa-solid fa-trash mr-2"></i> {@confirm_label}
        </button>
      </div>
    </.modal>
    """
  end

  @doc """
  Renders a generic card.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :header
  slot :footer
  slot :image

  def card(assigns) do
    ~H"""
    <div class={["glass-panel rounded-xl overflow-hidden", @class]}>
      <figure :if={@image != []}>
        {render_slot(@image)}
      </figure>
      <div class="card-body p-5">
        <h2 :if={@header != []} class="card-title mb-2">
          {render_slot(@header)}
        </h2>
        {render_slot(@inner_block)}
        <div :if={@footer != []} class="card-actions justify-end mt-4">
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end
end
