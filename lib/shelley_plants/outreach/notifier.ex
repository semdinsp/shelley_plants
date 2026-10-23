defmodule ShelleyPlants.Outreach.Notifier do
  @moduledoc """
  Emails for the contact form and newsletter signups.

  Recipients come from the `:outreach` config (see `config/runtime.exs`):
  contact messages go to `:contact_recipient`, every email to someone else is
  BCC'd to `:bcc`, and `:bcc` gets a notice of each new registration.
  """

  alias ShelleyPlants.{EmailLayout, Outreach}
  alias ShelleyPlants.Accounts.User
  alias ShelleyPlants.Outreach.{ContactMessage, NewsletterSubscriber}

  @site_name EmailLayout.site_name()

  @doc """
  Sends a contact-form message to the site owner. Replying to the email
  replies straight to the person who wrote in.
  """
  def deliver_contact_notification(%ContactMessage{} = message) do
    %{
      subject: "New message from #{message.name} via the website",
      preheader: String.slice(message.message, 0, 120),
      heading: "New contact form message",
      greeting: "Hi Shelley,",
      paragraphs: [
        "Someone sent a message through the Contact Us page. " <>
          "Reply to this email to answer them directly."
      ],
      details: [
        {"Name", message.name},
        {"Email", message.email},
        {"Message", message.message}
      ],
      button: "View all messages",
      url: EmailLayout.site_url() <> "/admin/contact-messages"
    }
    |> EmailLayout.build(
      to: config(:contact_recipient),
      bcc: config(:bcc),
      reply_to: {message.name, message.email}
    )
    |> EmailLayout.deliver()
  end

  @doc "Sends a welcome email to a new newsletter subscriber."
  def deliver_newsletter_welcome(%NewsletterSubscriber{} = subscriber) do
    greeting =
      case subscriber.name do
        name when is_binary(name) and name != "" -> "Hi #{name},"
        _ -> "Hi there,"
      end

    %{
      subject: "Welcome to the #{@site_name} newsletter",
      preheader: "You're signed up for news about native plants, sales and events.",
      heading: "You're on the list!",
      greeting: greeting,
      paragraphs: [
        "Thank you for signing up for the #{@site_name} newsletter.",
        "We'll be in touch with news about Ontario native plants: what's in stock, " <>
          "upcoming plant sales and events, and tips for growing a garden that " <>
          "supports pollinators and local wildlife.",
        "In the meantime, take a look at what's available now."
      ],
      button: "Shop native plants",
      url: EmailLayout.site_url() <> "/plants/gallery",
      footnotes: [
        "You're receiving this because #{subscriber.email} was signed up on our website.",
        "Didn't sign up, or changed your mind? Use the Unsubscribe link below."
      ],
      unsubscribe_url: unsubscribe_url(subscriber)
    }
    |> EmailLayout.build(to: subscriber.email, bcc: config(:bcc))
    |> EmailLayout.deliver()
  end

  @doc """
  Tells the `:bcc` list that someone registered an account. Sent as its own
  email rather than BCC'ing the registration email, because that email holds
  a one-time login link for the new account.
  """
  def deliver_registration_notice(%User{} = user) do
    %{
      subject: "New account registration: #{user.email}",
      preheader: "#{user.email} registered an account on the website.",
      heading: "New account registration",
      greeting: "Hi,",
      paragraphs: ["Someone registered an account on the website."],
      details: [{"Email", user.email}]
    }
    |> EmailLayout.build(to: config(:bcc))
    |> EmailLayout.deliver()
  end

  @doc """
  The subscriber's personal unsubscribe link. Every newsletter email must
  include it (Canada's anti-spam law, CASL).
  """
  def unsubscribe_url(%NewsletterSubscriber{} = subscriber) do
    EmailLayout.site_url() <> "/newsletter/unsubscribe/" <> Outreach.unsubscribe_token(subscriber)
  end

  defp config(key), do: Application.fetch_env!(:shelley_plants, :outreach)[key]
end
