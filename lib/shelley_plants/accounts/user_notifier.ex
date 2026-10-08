defmodule ShelleyPlants.Accounts.UserNotifier do
  alias ShelleyPlants.Accounts.User
  alias ShelleyPlants.EmailLayout

  @site_name EmailLayout.site_name()

  # Delivers a branded HTML + plain-text email (see ShelleyPlants.EmailLayout).
  defp deliver(recipient, subject, content) do
    %{
      subject: subject,
      preheader: content.preheader,
      heading: content.heading,
      greeting: content.greeting,
      paragraphs: [content.body],
      button: content.button,
      url: content.url,
      footnotes: [content.expiry, content.ignore]
    }
    |> EmailLayout.build(to: recipient)
    |> EmailLayout.deliver()
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Confirm your new email address", %{
      preheader: "Confirm the change to your #{@site_name} email address.",
      heading: "Confirm your new email",
      greeting: "Hi #{user.email},",
      body:
        "We received a request to change the email address on your account. " <>
          "Click the button below to confirm the change.",
      button: "Confirm email change",
      url: url,
      expiry: "This link expires in 7 days.",
      ignore: "If you didn't request this change, you can safely ignore this email."
    })
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Your #{@site_name} login link", %{
      preheader: "Your login link for #{@site_name}.",
      heading: "Log in to your account",
      greeting: "Hi #{user.email},",
      body: "Click the button below to log in to #{@site_name}. No password needed.",
      button: "Log in",
      url: url,
      expiry: "This link expires in 15 minutes and can only be used once.",
      ignore: "If you didn't request this email, you can safely ignore it."
    })
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Welcome to #{@site_name} — confirm your account", %{
      preheader: "Confirm your email to finish setting up your account.",
      heading: "Welcome to #{@site_name}",
      greeting: "Hi #{user.email},",
      body:
        "Thanks for signing up! Click the button below to confirm your email " <>
          "address and log in.",
      button: "Confirm my account",
      url: url,
      expiry: "This link expires in 15 minutes and can only be used once.",
      ignore: "If you didn't create an account with us, you can safely ignore this email."
    })
  end
end
