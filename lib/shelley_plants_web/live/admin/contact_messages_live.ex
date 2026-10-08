defmodule ShelleyPlantsWeb.Admin.ContactMessagesLive do
  use ShelleyPlantsWeb, :live_view

  alias ShelleyPlants.Outreach

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Contact Messages
        <:subtitle>
          {@count} {if @count == 1, do: "message", else: "messages"} from the Contact Us page, newest first.
        </:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="btn btn-ghost gap-2">
            <.icon name="hero-arrow-left" class="size-4" /> Admin
          </.link>
        </:actions>
      </.header>

      <p :if={@count == 0} class="mt-8 text-base-content/60">No messages yet.</p>

      <div id="contact-messages" phx-update="stream" class="mt-6 space-y-4">
        <article
          :for={{id, message} <- @streams.messages}
          id={id}
          class="card bg-base-100 border border-base-200"
        >
          <div class="card-body p-5 gap-3">
            <div class="flex flex-wrap items-start justify-between gap-2">
              <div>
                <p class="font-semibold">{message.name}</p>
                <a href={"mailto:#{message.email}"} class="text-sm text-primary hover:underline">
                  {message.email}
                </a>
              </div>
              <div class="flex items-center gap-2">
                <time
                  class="text-xs text-base-content/50"
                  datetime={DateTime.to_iso8601(message.inserted_at)}
                >
                  {Calendar.strftime(message.inserted_at, "%b %-d, %Y")}
                </time>
                <button
                  type="button"
                  phx-click="delete"
                  phx-value-id={message.id}
                  data-confirm={"Delete the message from #{message.name}?"}
                  class="btn btn-ghost btn-sm text-error"
                  aria-label={"Delete message from #{message.name}"}
                >
                  <.icon name="hero-trash" class="size-4" /> Delete
                </button>
              </div>
            </div>
            <p class="text-sm whitespace-pre-wrap break-words">{message.message}</p>
          </div>
        </article>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    messages = Outreach.list_contact_messages(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(page_title: "Contact Messages", count: length(messages))
     |> stream(:messages, messages)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    scope = socket.assigns.current_scope
    message = Outreach.get_contact_message!(scope, id)
    {:ok, _} = Outreach.delete_contact_message(scope, message)

    {:noreply,
     socket
     |> update(:count, &(&1 - 1))
     |> stream_delete(:messages, message)
     |> put_flash(:info, "Message from #{message.name} deleted.")}
  end
end
