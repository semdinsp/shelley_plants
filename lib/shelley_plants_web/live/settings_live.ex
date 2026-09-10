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

      <section class="mt-12" id="mcp-tokens" phx-hook=".CopyMcpToken">
        <h2 class="text-lg font-semibold mb-4">MCP tokens</h2>
        <p class="text-sm text-zinc-600 mb-4">
          Create a token to let an MCP client (e.g. Claude) act as you. Each token
          is shown only once, right after creation — copy it somewhere safe.
        </p>

        <table :if={@mcp_tokens != []} class="w-full text-sm mb-6">
          <thead>
            <tr class="text-left border-b border-zinc-200">
              <th class="py-2">Name</th>
              <th class="py-2">Created</th>
              <th class="py-2">Status</th>
              <th class="py-2"></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={token <- @mcp_tokens} class="border-b border-zinc-100">
              <td class="py-2">{token.name}</td>
              <td class="py-2">{Calendar.strftime(token.inserted_at, "%Y-%m-%d %H:%M UTC")}</td>
              <td class="py-2">
                <span :if={token.revoked_at} class="text-zinc-400">Revoked</span>
                <span :if={!token.revoked_at} class="text-green-700">Active</span>
              </td>
              <td class="py-2 text-right">
                <.button
                  :if={!token.revoked_at}
                  phx-click="revoke_mcp_token"
                  phx-value-id={token.id}
                  data-confirm={"Revoke \"#{token.name}\"? Any client using it will stop working immediately."}
                >
                  Revoke
                </.button>
              </td>
            </tr>
          </tbody>
        </table>
        <p :if={@mcp_tokens == []} class="text-sm text-zinc-500 mb-6">
          No MCP tokens yet.
        </p>

        <.form for={@mcp_token_form} id="create-mcp-token-form" phx-submit="create_mcp_token">
          <div class="flex items-end gap-4">
            <div class="flex-1">
              <.input
                field={@mcp_token_form[:name]}
                type="text"
                label="Token name"
                placeholder="claude-desktop"
              />
            </div>
            <.button variant="primary" phx-disable-with="Creating...">
              <.icon name="hero-key" /> Create token
            </.button>
          </div>
        </.form>
      </section>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyMcpToken">
      export default {
        mounted() {
          this.handleEvent("copy-mcp-token", ({token}) => {
            navigator.clipboard.writeText(token).catch(() => {})
          })
        }
      }
    </script>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:language_form, to_form(Accounts.change_user_preferences(user)))
     |> assign(:mcp_tokens, Accounts.list_mcp_tokens(user))
     |> assign(:mcp_token_form, to_form(%{"name" => ""}, as: "mcp_token"))}
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

  def handle_event("create_mcp_token", %{"mcp_token" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.create_mcp_token(user, params) do
      {:ok, raw_token, _mcp_token} ->
        {:noreply,
         socket
         |> assign(:mcp_tokens, Accounts.list_mcp_tokens(user))
         |> assign(:mcp_token_form, to_form(%{"name" => ""}, as: "mcp_token"))
         |> push_event("copy-mcp-token", %{token: raw_token})
         |> put_flash(
           :info,
           "Token created and copied to your clipboard. Save it now — it won't be shown again."
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :mcp_token_form, to_form(changeset, as: "mcp_token"))}
    end
  end

  def handle_event("revoke_mcp_token", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    token = Enum.find(socket.assigns.mcp_tokens, &(&1.id == id && &1.user_id == user.id))

    case token && Accounts.revoke_mcp_token(user, token) do
      {:ok, _mcp_token} ->
        {:noreply,
         socket
         |> assign(:mcp_tokens, Accounts.list_mcp_tokens(user))
         |> put_flash(:info, "Token revoked.")}

      _ ->
        {:noreply, put_flash(socket, :error, "Token not found.")}
    end
  end
end
