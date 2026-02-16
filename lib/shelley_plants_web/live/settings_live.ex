defmodule ShelleyPlantsWeb.SettingsLive do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Accounts

  on_mount {ShelleyPlantsWeb.UserAuth, :require_authenticated}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Settings
        <:subtitle>Manage your preferences.</:subtitle>
      </.header>

      <section class="mt-8">
        <h2 class="text-lg font-semibold mb-4">Language</h2>
        <.form
          for={@language_form}
          id="language-form"
          phx-change="validate_language"
          phx-submit="save_language"
        >
          <.input
            field={@language_form[:preferred_language]}
            type="select"
            label="Preferred language"
            options={[{"English", "en"}, {"French / Français", "fr"}]}
          />
          <footer>
            <.button phx-disable-with="Saving..." variant="primary">Save language</.button>
          </footer>
        </.form>
      </section>

      <section :if={@current_scope.admin?} class="mt-12">
        <h2 class="text-lg font-semibold mb-4">Plant catalog management</h2>
        <p class="text-sm text-zinc-600 mb-4">
          As an administrator, you can manage the native plant catalog.
        </p>
        <div class="flex gap-4">
          <.button variant="primary" navigate={~p"/plants/new"}>
            <.icon name="hero-plus" /> Add new plant
          </.button>
          <.button navigate={~p"/plants"}>
            <.icon name="hero-list-bullet" /> View all plants
          </.button>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:language_form, to_form(Accounts.change_user_preferences(user)))}
  end

  @impl true
  def handle_event("validate_language", %{"user" => params}, socket) do
    user = socket.assigns.current_scope.user
    changeset = Accounts.change_user_preferences(user, params)
    {:noreply, assign(socket, language_form: to_form(changeset, action: :validate))}
  end

  def handle_event("save_language", %{"user" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_preferences(user, params) do
      {:ok, _user} ->
        {:noreply, put_flash(socket, :info, "Language preference saved.")}

      {:error, changeset} ->
        {:noreply, assign(socket, language_form: to_form(changeset))}
    end
  end
end
