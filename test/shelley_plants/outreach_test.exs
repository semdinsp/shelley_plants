defmodule ShelleyPlants.OutreachTest do
  use ShelleyPlants.DataCase, async: true

  import Swoosh.TestAssertions

  alias ShelleyPlants.Accounts.Scope
  alias ShelleyPlants.Outreach
  alias ShelleyPlants.Outreach.{ContactMessage, NewsletterSubscriber}

  @admin %Scope{admin?: true}

  describe "submit_contact_message/1" do
    test "saves the message and emails it to Shelley, BCC'ing Scott" do
      {:ok, %ContactMessage{} = message} =
        Outreach.submit_contact_message(%{
          "name" => " Jane Gardener ",
          "email" => "jane@example.com",
          "message" => "Do you have <b>milkweed</b>?\nThanks!"
        })

      assert message.name == "Jane Gardener"

      assert_email_sent(fn email ->
        assert email.to == [{"", "shellsphoto44@gmail.com"}]
        assert email.bcc == [{"", "scott.sproule@gmail.com"}]
        assert email.reply_to == {"Jane Gardener", "jane@example.com"}
        assert email.subject =~ "Jane Gardener"
        assert email.text_body =~ "Do you have <b>milkweed</b>?\nThanks!"
        assert email.html_body =~ "&lt;b&gt;milkweed&lt;/b&gt;"
        refute email.html_body =~ "<b>milkweed"
        true
      end)
    end

    test "returns errors and sends nothing for invalid input" do
      assert {:error, changeset} =
               Outreach.submit_contact_message(%{"name" => "", "email" => "nope"})

      assert %{name: [_], email: [_], message: [_]} = errors_on(changeset)
      assert_no_email_sent()
    end
  end

  describe "subscribe/1" do
    test "adds the subscriber and sends a welcome email, BCC'ing Scott" do
      {:ok, %NewsletterSubscriber{} = sub} =
        Outreach.subscribe(%{"name" => "Sam", "email" => "sam@example.com"})

      assert sub.email == "sam@example.com"

      assert_email_sent(fn email ->
        assert email.to == [{"", "sam@example.com"}]
        assert email.bcc == [{"", "scott.sproule@gmail.com"}]
        assert email.subject =~ "Welcome"
        assert email.html_body =~ "Hi Sam,"
        assert email.html_body =~ "/plants/gallery"
      end)
    end

    test "does not duplicate or re-email an existing subscriber (case-insensitive)" do
      {:ok, sub} = Outreach.subscribe(%{"email" => "sam@example.com"})
      assert_email_sent()

      assert {:existing, existing} = Outreach.subscribe(%{"email" => "SAM@example.com"})
      assert existing.id == sub.id
      assert_no_email_sent()
      assert length(Outreach.list_subscribers(@admin)) == 1
    end

    test "rejects an invalid email" do
      assert {:error, changeset} = Outreach.subscribe(%{"email" => "not-an-email"})
      assert %{email: ["must be a valid email address"]} = errors_on(changeset)
    end
  end

  describe "unsubscribe" do
    test "the welcome email has an unsubscribe link and one-click headers" do
      {:ok, sub} = Outreach.subscribe(%{"email" => "sam@example.com"})

      assert_email_sent(fn email ->
        assert ["<" <> url] =
                 Regex.run(
                   ~r{<[^>]+/newsletter/unsubscribe/[^>]+},
                   email.headers["List-Unsubscribe"]
                 )

        assert email.headers["List-Unsubscribe-Post"] == "List-Unsubscribe=One-Click"
        assert email.html_body =~ ~s(href="#{url}")
        assert email.text_body =~ "Unsubscribe: #{url}"

        token = url |> String.split("/") |> List.last()

        assert {:ok, %NewsletterSubscriber{id: id}} =
                 Outreach.subscriber_for_unsubscribe_token(token)

        assert id == sub.id
      end)
    end

    test "a token removes its subscriber, and is safe to use twice" do
      {:ok, sub} = Outreach.subscribe(%{"email" => "sam@example.com"})
      token = Outreach.unsubscribe_token(sub)

      assert {:ok, %NewsletterSubscriber{id: id}} =
               Outreach.subscriber_for_unsubscribe_token(token)

      assert id == sub.id

      assert Outreach.unsubscribe(token) == :ok
      assert Outreach.list_subscribers(@admin) == []
      assert Outreach.subscriber_for_unsubscribe_token(token) == {:ok, nil}
      assert Outreach.unsubscribe(token) == :ok
    end

    test "a tampered token is rejected" do
      {:ok, sub} = Outreach.subscribe(%{"email" => "sam@example.com"})
      token = Outreach.unsubscribe_token(sub)

      assert Outreach.unsubscribe(token <> "x") == {:error, :invalid}
      assert Outreach.unsubscribe("not-a-token") == {:error, :invalid}
      assert length(Outreach.list_subscribers(@admin)) == 1
    end
  end

  describe "admin functions" do
    test "list and delete require an admin scope" do
      {:ok, message} =
        Outreach.submit_contact_message(%{
          "name" => "A",
          "email" => "a@example.com",
          "message" => "Hi"
        })

      {:ok, sub} = Outreach.subscribe(%{"email" => "b@example.com"})

      non_admin = %Scope{admin?: false}
      assert_raise FunctionClauseError, fn -> Outreach.list_contact_messages(non_admin) end
      assert_raise FunctionClauseError, fn -> Outreach.delete_subscriber(non_admin, sub) end

      assert {:ok, _} = Outreach.delete_contact_message(@admin, message)
      assert {:ok, _} = Outreach.delete_subscriber(@admin, sub)
      assert Outreach.list_contact_messages(@admin) == []
      assert Outreach.list_subscribers(@admin) == []
    end
  end
end
