defmodule ShelleyPlantsWeb.Admin.NewsletterLive do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Outreach

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Newsletter Signups
        <:subtitle>
          {@count} {if @count == 1, do: "subscriber", else: "subscribers"}, newest first.
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="btn btn-ghost gap-2">
            <.icon name="hero-arrow-left" class="size-4" /> Admin
          </.link>
        </:actions>
      </.header>

      <p :if={@count == 0} class="mt-8 text-base-content/60">No signups yet.</p>

      <.table :if={@count > 0} id="subscribers" rows={@streams.subscribers}>
        <:col :let={{_id, subscriber}} label="Name">{subscriber.name || "—"}</:col>
        <:col :let={{_id, subscriber}} label="Email">
          <a href={"mailto:#{subscriber.email}"} class="text-primary hover:underline">
            {subscriber.email}
          </a>
        </:col>
        <:col :let={{_id, subscriber}} label="Signed up">
          {Calendar.strftime(subscriber.inserted_at, "%b %-d, %Y")}
        </:col>
        <:action :let={{_id, subscriber}}>
          <button
            type="button"
            phx-click="delete"
            phx-value-id={subscriber.id}
            data-confirm={"Remove #{subscriber.email} from the newsletter list?"}
            class="btn btn-ghost btn-sm text-error"
            aria-label={"Remove #{subscriber.email}"}
          >
            <.icon name="hero-trash" class="size-4" /> Remove
          </button>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    subscribers = Outreach.list_subscribers(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(page_title: "Newsletter Signups", count: length(subscribers))
     |> stream(:subscribers, subscribers)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    subscriber = Outreach.get_subscriber!(scope, id)
    {:ok, _} = Outreach.delete_subscriber(scope, subscriber)

    {:noreply,
     socket
     |> update(:count, &(&1 - 1))
     |> stream_delete(:subscribers, subscriber)
     |> put_flash(:info, "#{subscriber.email} removed from the newsletter list.")}
  end
end
