defmodule ShelleyPlantsWeb.PlantLive.Show do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Catalog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@plant.common_name}
        <:subtitle><em>{@plant.latin_name}</em></:subtitle>
        <:actions>
          <.button navigate={~p"/plants"}>
            <.icon name="hero-arrow-left" /> Back to plants
          </.button>
          <.button
            :if={@current_scope && @current_scope.admin?}
            variant="primary"
            navigate={~p"/plants/#{@plant}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit plant
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Common name">{@plant.common_name}</:item>
        <:item title="Latin name"><em>{@plant.latin_name}</em></:item>
        <:item title="Plant type">{@plant.plant_type}</:item>
        <:item title="Flower color">{@plant.flower_color}</:item>
        <:item title="Bloom time">{@plant.bloom_time}</:item>
        <:item title="Height">{@plant.height}</:item>
        <:item title="Chelsea chop">{if @plant.chelsea_chop, do: "Yes", else: "No"}</:item>
        <:item title="Light requirements">{@plant.light_requirements}</:item>
        <:item title="Moisture">{@plant.moisture}</:item>
        <:item title="Native to Ontario">{if @plant.native_ontario, do: "Yes", else: "No"}</:item>
        <:item title="Locally native">{if @plant.locally_native, do: "Yes", else: "No"}</:item>
        <:item title="Deer resistant">{if @plant.deer_resistant, do: "Yes", else: "No"}</:item>
        <:item :if={@plant.ecological_benefit} title="Ecological benefit">
          {@plant.ecological_benefit}
        </:item>
        <:item :if={@plant.notes} title="Notes">{@plant.notes}</:item>
        <:item :if={@plant.picture} title="Picture">
          <img src={@plant.picture} alt={@plant.common_name} class="max-w-sm rounded" />
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Catalog.subscribe_plants()
    end

    {:ok,
     socket
     |> assign(:page_title, "Plant Details")
     |> assign(:plant, Catalog.get_plant!(id))}
  end

  @impl true
  def handle_info(
        {:updated, %ShelleyPlants.Catalog.Plant{id: id} = plant},
        %{assigns: %{plant: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :plant, plant)}
  end

  def handle_info(
        {:deleted, %ShelleyPlants.Catalog.Plant{id: id}},
        %{assigns: %{plant: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "This plant has been removed.")
     |> push_navigate(to: ~p"/plants")}
  end

  def handle_info({type, %ShelleyPlants.Catalog.Plant{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
