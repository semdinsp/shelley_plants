defmodule ShelleyPlants.Outreach do
  @moduledoc """
  The Outreach context: contact-form messages and newsletter signups.

  Anyone may submit a message or subscribe. Only admin users may list or
  delete them.
  """

  import Ecto.Query, warn: false
  alias ShelleyPlants.Repo

  alias ShelleyPlants.Accounts.Scope
  alias ShelleyPlants.Outreach.{ContactMessage, NewsletterSubscriber, Notifier}

  ## Contact messages

  @doc """
  Saves a contact-form message and emails it to the site owner.

  A failed email is logged by the notifier but doesn't fail the submission,
  since the message is already saved and visible in the admin.
  """
  def submit_contact_message(attrs) do
    with {:ok, message} <- %ContactMessage{} |> ContactMessage.changeset(attrs) |> Repo.insert() do
      Notifier.deliver_contact_notification(message)
      {:ok, message}
    end
  end

  def change_contact_message(%ContactMessage{} = message, attrs \\ %{}) do
    ContactMessage.changeset(message, attrs)
  end

  @doc "Lists contact messages, newest first. Requires an admin scope."
  def list_contact_messages(%Scope{admin?: true}) do
    Repo.all(from m in ContactMessage, order_by: [desc: m.inserted_at])
  end

  def get_contact_message!(%Scope{admin?: true}, id), do: Repo.get!(ContactMessage, id)

  @doc "Deletes a contact message. Requires an admin scope."
  def delete_contact_message(%Scope{admin?: true}, %ContactMessage{} = message) do
    Repo.delete(message)
  end

  ## Newsletter

  @doc """
  Signs someone up for the newsletter and sends them a welcome email.

  Returns `{:ok, subscriber}` for a new signup and `{:existing, subscriber}`
  when the email is already on the list. No email is sent for an existing
  subscriber, so the form can't be used to spam someone's inbox.
  """
  def subscribe(attrs) do
    changeset = NewsletterSubscriber.changeset(%NewsletterSubscriber{}, attrs)

    with {:ok, subscriber} <- Repo.insert(changeset) do
      Notifier.deliver_newsletter_welcome(subscriber)
      {:ok, subscriber}
    else
      {:error, %Ecto.Changeset{errors: errors} = changeset} ->
        with {_, opts} <- Keyword.get(errors, :email),
             :unique <- opts[:constraint],
             %NewsletterSubscriber{} = existing <-
               Repo.get_by(NewsletterSubscriber,
                 email: Ecto.Changeset.get_field(changeset, :email)
               ) do
          {:existing, existing}
        else
          _ -> {:error, changeset}
        end
    end
  end

  def change_subscriber(%NewsletterSubscriber{} = subscriber, attrs \\ %{}) do
    NewsletterSubscriber.changeset(subscriber, attrs)
  end

  @doc "Lists newsletter subscribers, newest first. Requires an admin scope."
  def list_subscribers(%Scope{admin?: true}) do
    Repo.all(from s in NewsletterSubscriber, order_by: [desc: s.inserted_at])
  end

  def get_subscriber!(%Scope{admin?: true}, id), do: Repo.get!(NewsletterSubscriber, id)

  @doc "Removes someone from the newsletter list. Requires an admin scope."
  def delete_subscriber(%Scope{admin?: true}, %NewsletterSubscriber{} = subscriber) do
    Repo.delete(subscriber)
  end
end
