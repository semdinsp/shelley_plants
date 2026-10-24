defmodule ShelleyPlantsWeb.CustomerContactTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ShelleyPlants.AccountsFixtures

  alias CustomerContact.Recipient
  alias ShelleyPlants.{CustomerContactHost, Outreach}

  @admin_pages ["/admin/contact", "/admin/contact/audience", "/admin/contact/campaigns/new"]

  describe "admin pages" do
    test "logged-out visitors are redirected", %{conn: conn} do
      for path <- @admin_pages do
        assert {:error, {:redirect, _}} = live(conn, path)
      end
    end

    test "non-admins are redirected", %{conn: conn} do
      conn = log_in_user(conn, user_fixture())

      for path <- @admin_pages do
        assert {:error, {:redirect, _}} = live(conn, path)
      end
    end

    test "admins can load them", %{conn: conn} do
      {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user_fixture(), true)
      conn = log_in_user(conn, admin)

      for path <- @admin_pages do
        assert {:ok, _lv, _html} = live(conn, path)
      end
    end

    test "their home icon links back to the admin dashboard", %{conn: conn} do
      {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user_fixture(), true)
      {:ok, lv, _html} = conn |> log_in_user(admin) |> live("/admin/contact/campaigns/new")

      assert has_element?(lv, ~s|#cc-home[href="/admin"]|)
      refute has_element?(lv, "#missing-postal-address")
    end

    test "the admin dashboard links to them", %{conn: conn} do
      {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user_fixture(), true)
      {:ok, lv, _html} = conn |> log_in_user(admin) |> live(~p"/admin")

      assert has_element?(lv, ~s|a[href="/admin/contact"]|, "Customer contact")
    end
  end

  describe "list_recipients/0" do
    test "returns current newsletter subscribers with string refs" do
      {:ok, sam} = Outreach.subscribe(%{"name" => "Sam", "email" => "sam@example.com"})
      {:ok, gone} = Outreach.subscribe(%{"email" => "gone@example.com"})
      :ok = Outreach.unsubscribe(Outreach.unsubscribe_token(gone))

      # Registered users who never subscribed aren't contacted
      user_fixture()

      assert [%Recipient{} = recipient] = CustomerContactHost.list_recipients()
      assert recipient.ref == sam.id
      assert is_binary(recipient.ref)
      assert recipient.email == "sam@example.com"
      assert recipient.name == "Sam"
    end
  end

  test "brand matches the site's email sender and colours" do
    brand = CustomerContactHost.brand()
    sender = Application.fetch_env!(:shelley_plants, :mail_sender)

    assert brand.from == {"Biosphere Native Plants", sender[:address]}
    assert brand.postal_address =~ "Westport, ON"
    assert CustomerContact.Campaigns.postal_address?()
    assert brand.primary_color == "#0c170d"
  end

  test "the tracking pixel works without a session", %{conn: conn} do
    conn = get(conn, "/cc/o/anything.gif")

    assert conn.status == 200
    assert [content_type] = get_resp_header(conn, "content-type")
    assert content_type =~ "image/gif"
  end
end
