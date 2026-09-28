defmodule ShelleyPlants.Accounts.UserNotifierTest do
  use ExUnit.Case, async: true

  alias ShelleyPlants.Accounts.{User, UserNotifier}

  @url "https://biosphere-native-plants.ca/users/log-in/some-token"

  describe "deliver_login_instructions/2" do
    test "sends a branded HTML login email with a plain-text fallback" do
      user = %User{email: "shelley@example.com", confirmed_at: DateTime.utc_now()}

      {:ok, email} = UserNotifier.deliver_login_instructions(user, @url)

      assert email.subject == "Your Biosphere Native Plants login link"
      assert email.html_body =~ ~s|href="#{@url}"|
      assert email.html_body =~ "Log in to your account"
      assert email.html_body =~ "/images/biologo.jpg"
      assert email.text_body =~ @url
      assert email.text_body =~ "expires in 15 minutes"
    end

    test "sends a welcome/confirmation email to unconfirmed users" do
      user = %User{email: "new@example.com", confirmed_at: nil}

      {:ok, email} = UserNotifier.deliver_login_instructions(user, @url)

      assert email.subject =~ "confirm your account"
      assert email.html_body =~ "Confirm my account"
      assert email.text_body =~ @url
    end

    test "escapes user-supplied values in the HTML" do
      user = %User{email: "<script>@example.com", confirmed_at: DateTime.utc_now()}

      {:ok, email} = UserNotifier.deliver_login_instructions(user, @url)

      refute email.html_body =~ "<script>"
      assert email.html_body =~ "&lt;script&gt;@example.com"
    end
  end

  describe "deliver_update_email_instructions/2" do
    test "sends a branded HTML email-change confirmation" do
      user = %User{email: "shelley@example.com"}

      {:ok, email} = UserNotifier.deliver_update_email_instructions(user, @url)

      assert email.subject == "Confirm your new email address"
      assert email.html_body =~ "Confirm email change"
      assert email.html_body =~ ~s|href="#{@url}"|
      assert email.text_body =~ "expires in 7 days"
    end
  end
end
