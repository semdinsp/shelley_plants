defmodule ShelleyPlantsWeb.ContactControllerTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import Swoosh.TestAssertions

  alias ShelleyPlants.Accounts.Scope
  alias ShelleyPlants.Outreach

  @admin %Scope{admin?: true}
  @message %{"name" => "Jane", "email" => "jane@example.com", "message" => "Hello!"}

  defp turnstile_passes(_context) do
    Req.Test.stub(ShelleyPlants.Turnstile, &Req.Test.json(&1, %{"success" => true}))
    :ok
  end

  defp turnstile_fails(_context) do
    Req.Test.stub(ShelleyPlants.Turnstile, &Req.Test.json(&1, %{"success" => false}))
    :ok
  end

  test "GET /contact shows both forms and the Turnstile widget", %{conn: conn} do
    html = conn |> get(~p"/contact") |> html_response(200)

    assert html =~ "Contact Us"
    assert html =~ ~s(id="contact-form")
    assert html =~ ~s(id="newsletter-form")
    assert html =~ ~s(class="cf-turnstile")
    assert html =~ "challenges.cloudflare.com/turnstile"
  end

  describe "when the bot check passes" do
    setup :turnstile_passes

    test "a contact message is saved and emailed", %{conn: conn} do
      conn =
        post(conn, ~p"/contact", %{"contact_message" => @message, "cf-turnstile-response" => "t"})

      assert redirected_to(conn) == ~p"/contact"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Thank you"
      assert [%{name: "Jane"}] = Outreach.list_contact_messages(@admin)
      assert_email_sent(to: "shellsphoto44@gmail.com")
    end

    test "an invalid contact message re-renders with errors", %{conn: conn} do
      conn =
        post(conn, ~p"/contact", %{
          "contact_message" => %{@message | "email" => "nope"},
          "cf-turnstile-response" => "t"
        })

      assert html_response(conn, 422) =~ "must be a valid email address"
      assert Outreach.list_contact_messages(@admin) == []
    end

    test "a newsletter signup is saved and gets a welcome email", %{conn: conn} do
      conn =
        post(conn, ~p"/newsletter", %{
          "newsletter_subscriber" => %{"name" => "Sam", "email" => "sam@example.com"},
          "cf-turnstile-response" => "t"
        })

      assert redirected_to(conn) == ~p"/contact"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "signed up"
      assert [%{email: "sam@example.com"}] = Outreach.list_subscribers(@admin)
      assert_email_sent(to: "sam@example.com")
    end

    test "filling the hidden honeypot field drops the submission", %{conn: conn} do
      conn =
        post(conn, ~p"/contact", %{
          "contact_message" => @message,
          "website" => "http://spam.example",
          "cf-turnstile-response" => "t"
        })

      assert redirected_to(conn) == ~p"/contact"
      assert Outreach.list_contact_messages(@admin) == []
      assert_no_email_sent()
    end
  end

  describe "when the bot check fails" do
    setup :turnstile_fails

    test "the contact message is not saved and the form keeps its input", %{conn: conn} do
      conn =
        post(conn, ~p"/contact", %{"contact_message" => @message, "cf-turnstile-response" => "t"})

      html = html_response(conn, 422)
      assert html =~ "Please complete the verification check"
      assert html =~ "jane@example.com"
      assert Outreach.list_contact_messages(@admin) == []
      assert_no_email_sent()
    end

    test "the newsletter signup is not saved", %{conn: conn} do
      conn =
        post(conn, ~p"/newsletter", %{
          "newsletter_subscriber" => %{"email" => "sam@example.com"}
        })

      assert html_response(conn, 422) =~ "Please complete the verification check"
      assert Outreach.list_subscribers(@admin) == []
    end
  end
end
