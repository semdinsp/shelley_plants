defmodule ShelleyPlantsWeb.PlantLive.Index do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Catalog

  @categories ~w(Wildflower Grass Shrub Tree)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Species List
        <:actions :if={@current_scope && @current_scope.admin?}>
          <.button variant="primary" navigate={~p"/plants/new"}>
            <.icon name="hero-plus" /> New Plant
          </.button>
        </:actions>
      </.header>

      <%!-- Category filter buttons --%>
      <div class="flex flex-wrap gap-2 mb-6">
        <.link
          patch={~p"/plants"}
          class={"btn btn-sm #{if @category == nil, do: "btn-primary", else: "btn-ghost"}"}
        >
          All
        </.link>
        <.link
          :for={cat <- @categories}
          patch={~p"/plants?category=#{cat}"}
          class={"btn btn-sm #{if @category == cat, do: "btn-primary", else: "btn-ghost"}"}
        >
          {cat}
        </.link>
      </div>

      <.table
        id="plants"
        rows={@streams.plants}
        row_click={fn {_id, plant} -> JS.navigate(~p"/plants/#{plant}") end}
      >
        <:col :let={{_id, plant}} label="Photo">
          <img
            :if={plant.picture}
            src={plant.picture}
            alt={plant.common_name}
            class="h-12 w-12 rounded object-cover"
          />
        </:col>
        <:col :let={{_id, plant}} label="Common name">{plant.common_name}</:col>
        <:col :let={{_id, plant}} label="Latin name"><em>{plant.latin_name}</em></:col>
        <:col :let={{_id, plant}} label="Category">{plant.category}</:col>
        <:col :let={{_id, plant}} label="Plant type">{plant.plant_type}</:col>
        <:col :let={{_id, plant}} label="Flower color">{plant.flower_color}</:col>
        <:col :let={{_id, plant}} label="Bloom time">{plant.bloom_time}</:col>
        <:col :let={{_id, plant}} label="Height">{plant.height}</:col>
        <:col :let={{_id, plant}} label="Light">{plant.light_requirements}</:col>
        <:col :let={{_id, plant}} label="Native (ON)">
          {cond do
            plant.locally_native -> "Yes (local)"
            plant.native_ontario -> "Yes"
            true -> "Non-native to Ontario"
          end}
        </:col>
        <:action :let={{_id, plant}}>
          <.link navigate={~p"/plants/#{plant}"} aria-label="View"><.icon name="hero-eye" class="size-5" /></.link>
        </:action>
        <:action :let={{_id, plant}} :if={@current_scope && @current_scope.admin?}>
          <.link navigate={~p"/plants/#{plant}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, plant}} :if={@current_scope && @current_scope.admin?}>
          <.link
            phx-click={JS.push("delete", value: %{id: plant.id}) |> hide("##{id}")}
            data-confirm="Are you sure you want to delete #{plant.common_name}?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Catalog.subscribe_plants()
    end

    {:ok,
     socket
     |> assign(:page_title, "Species List")
     |> assign(:categories, @categories)
     |> assign(:category, nil)
     |> stream(:plants, Catalog.list_plants())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    category = Map.get(params, "category")
    category = if category in @categories, do: category, else: nil

    {:noreply,
     socket
     |> assign(:category, category)
     |> stream(:plants, Catalog.list_plants_by_category(category), reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    plant = Catalog.get_plant!(id)
    {:ok, _} = Catalog.delete_plant(socket.assigns.current_scope, plant)

    {:noreply, stream_delete(socket, :plants, plant)}
  end

  @impl true
  def handle_info({type, %ShelleyPlants.Catalog.Plant{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :plants, Catalog.list_plants_by_category(socket.assigns.category),
       reset: true
     )}
  end
end
