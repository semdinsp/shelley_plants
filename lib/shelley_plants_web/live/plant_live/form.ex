defmodule ShelleyPlantsWeb.PlantLive.Form do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Catalog
  alias ShelleyPlants.Catalog.Plant

  on_mount {ShelleyPlantsWeb.UserAuth, :require_admin}

  @accepted_types ~w(.jpg .jpeg .png .webp)
  @max_file_size 5 * 1024 * 1024

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage plant records in the catalog.</:subtitle>
      </.header>

      <.form for={@form} id="plant-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:common_name]} type="text" label="Common name" />
        <.input field={@form[:latin_name]} type="text" label="Latin name" />
        <.input
          field={@form[:plant_type]}
          type="select"
          label="Plant type"
          options={[{"Perennial", "perennial"}, {"Annual", "annual"}]}
          prompt="Select plant type"
        />
        <.input field={@form[:flower_color]} type="text" label="Flower color" />
        <.input field={@form[:bloom_time]} type="text" label="Bloom time" />
        <.input field={@form[:height]} type="text" label="Height" />
        <.input field={@form[:light_requirements]} type="text" label="Light requirements" />
        <.input field={@form[:moisture]} type="text" label="Moisture" />
        <.input field={@form[:chelsea_chop]} type="checkbox" label="Chelsea chop" />
        <.input field={@form[:native_ontario]} type="checkbox" label="Native to Ontario" />
        <.input field={@form[:locally_native]} type="checkbox" label="Locally native" />
        <.input field={@form[:deer_resistant]} type="checkbox" label="Deer resistant" />
        <.input field={@form[:ecological_benefit]} type="textarea" label="Ecological benefit" />
        <.input field={@form[:notes]} type="textarea" label="Notes" />

        <%!-- Photo upload section --%>
        <div class="space-y-3 py-2">
          <p class="text-sm font-medium leading-6">Photo</p>

          <%!-- Current photo --%>
          <div :if={@plant.picture && !@clear_picture} class="space-y-2">
            <img
              src={@plant.picture}
              alt="Current photo"
              class="rounded-xl max-h-56 object-cover border border-base-300"
            />
            <button type="button" phx-click="delete_picture" class="btn btn-error btn-sm gap-2">
              <.icon name="hero-trash" /> Delete photo
            </button>
          </div>

          <%!-- Pending delete warning --%>
          <div :if={@clear_picture} class="alert alert-warning gap-3">
            <.icon name="hero-exclamation-triangle" class="size-5 shrink-0" />
            <span class="text-sm">Photo will be removed when you save.</span>
            <button type="button" phx-click="cancel_delete_picture" class="btn btn-sm ml-auto">
              Undo
            </button>
          </div>

          <%!-- Drop zone --%>
          <div
            class="flex flex-col items-center justify-center gap-3 rounded-xl border-2 border-dashed border-base-300 bg-base-200 px-6 py-8 text-center"
            phx-drop-target={@uploads.picture.ref}
          >
            <.icon name="hero-photo" class="size-8 text-base-content/40" />
            <div>
              <label
                for={@uploads.picture.ref}
                class="cursor-pointer font-medium text-primary hover:underline"
              >
                Choose a photo
              </label>
              <span class="text-sm text-base-content/60"> or drag and drop</span>
            </div>
            <p class="text-xs text-base-content/50">
              JPG, PNG or WebP · max 5 MB
            </p>
            <.live_file_input upload={@uploads.picture} class="sr-only" />
          </div>

          <%!-- Selected file entries --%>
          <div
            :for={entry <- @uploads.picture.entries}
            class="flex items-center gap-3 rounded-xl bg-base-200 p-3"
          >
            <.live_img_preview entry={entry} class="size-14 rounded-lg object-cover shrink-0" />
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium truncate">{entry.client_name}</p>
              <div class="w-full bg-base-300 rounded-full h-1.5 mt-1.5">
                <div
                  class="bg-primary h-1.5 rounded-full transition-all"
                  style={"width: #{entry.progress}%"}
                >
                </div>
              </div>
              <p class="text-xs text-base-content/50 mt-1">{entry.progress}%</p>
            </div>
            <button
              type="button"
              phx-click="cancel_upload"
              phx-value-ref={entry.ref}
              class="btn btn-ghost btn-sm btn-circle shrink-0"
              aria-label="Cancel upload"
            >
              <.icon name="hero-x-mark" />
            </button>
          </div>

          <%!-- Upload errors --%>
          <div
            :for={err <- upload_errors(@uploads.picture)}
            class="alert alert-error text-sm"
          >
            <.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
            {upload_error_message(err)}
          </div>

          <div :for={entry <- @uploads.picture.entries}>
            <div
              :for={err <- upload_errors(@uploads.picture, entry)}
              class="alert alert-error text-sm"
            >
              <.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
              {entry.client_name}: {upload_error_message(err)}
            </div>
          </div>
        </div>

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Plant</.button>
          <.button navigate={return_path(@return_to, @plant)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> allow_upload(:picture,
       accept: @accepted_types,
       max_entries: 1,
       max_file_size: @max_file_size
     )
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:clear_picture, false)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    plant = Catalog.get_plant!(id)

    socket
    |> assign(:page_title, "Edit Plant")
    |> assign(:plant, plant)
    |> assign(:form, to_form(Catalog.change_plant(plant)))
  end

  defp apply_action(socket, :new, _params) do
    plant = %Plant{}

    socket
    |> assign(:page_title, "New Plant")
    |> assign(:plant, plant)
    |> assign(:form, to_form(Catalog.change_plant(plant)))
  end

  @impl true
  def handle_event("validate", %{"plant" => plant_params}, socket) do
    changeset = Catalog.change_plant(socket.assigns.plant, plant_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"plant" => plant_params}, socket) do
    picture = process_picture(socket)
    plant_params = Map.put(plant_params, "picture", picture)
    save_plant(socket, socket.assigns.live_action, plant_params)
  end

  def handle_event("delete_picture", _params, socket) do
    {:noreply, assign(socket, :clear_picture, true)}
  end

  def handle_event("cancel_delete_picture", _params, socket) do
    {:noreply, assign(socket, :clear_picture, false)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :picture, ref)}
  end

  defp save_plant(socket, :edit, plant_params) do
    case Catalog.update_plant(socket.assigns.current_scope, socket.assigns.plant, plant_params) do
      {:ok, plant} ->
        {:noreply,
         socket
         |> put_flash(:info, "Plant updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, plant))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_plant(socket, :new, plant_params) do
    case Catalog.create_plant(socket.assigns.current_scope, plant_params) do
      {:ok, plant} ->
        {:noreply,
         socket
         |> put_flash(:info, "Plant created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, plant))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # ── Photo helpers ───────────────────────────────────────────────────────────

  # Consume any pending upload, delete the old file if replaced/cleared,
  # and return the final picture value for the plant record.
  defp process_picture(socket) do
    case consume_uploaded_entries(socket, :picture, fn %{path: tmp_path}, entry ->
           ext = entry.client_name |> Path.extname() |> String.downcase()
           filename = "#{entry.uuid}#{ext}"
           dest = Path.join(upload_dir(), filename)
           File.cp!(tmp_path, dest)
           {:ok, "/images/plants/#{filename}"}
         end) do
      [new_path] ->
        maybe_delete_file(socket.assigns.plant.picture)
        new_path

      [] ->
        if socket.assigns.clear_picture do
          maybe_delete_file(socket.assigns.plant.picture)
          nil
        else
          socket.assigns.plant.picture
        end
    end
  end

  # Only delete files we stored locally; ignore external URLs.
  defp maybe_delete_file(nil), do: :ok

  defp maybe_delete_file(picture) when is_binary(picture) do
    if String.starts_with?(picture, "/images/plants/") do
      picture |> Path.basename() |> then(&Path.join(upload_dir(), &1)) |> File.rm()
    end

    :ok
  end

  defp upload_dir do
    Application.app_dir(:shelley_plants, ["priv", "static", "images", "plants"])
  end

  defp upload_error_message(:too_large), do: "File is too large (max 5 MB)."
  defp upload_error_message(:not_accepted), do: "Unsupported file type. Use JPG, PNG, or WebP."
  defp upload_error_message(:too_many_files), do: "Only one photo can be uploaded at a time."
  defp upload_error_message(err), do: "Upload error: #{inspect(err)}"

  defp return_path("index", _plant), do: ~p"/plants"
  defp return_path("show", plant), do: ~p"/plants/#{plant}"
end
