defmodule ShelleyPlantsWeb.Admin.OutreachLiveTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import ShelleyPlants.AccountsFixtures

  alias ShelleyPlants.Accounts.Scope
  alias ShelleyPlants.Outreach

  @admin %Scope{admin?: true}

  defp log_in_admin(%{conn: conn}) do
    {:ok, admin} = ShelleyPlants.Accounts.set_user_admin(user_fixture(), true)
    %{conn: log_in_user(conn, admin)}
  end

  test "non-admins can't see the pages", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())
    assert {:error, {:redirect, _}} = live(conn, ~p"/admin/contact-messages")
    assert {:error, {:redirect, _}} = live(conn, ~p"/admin/newsletter")
  end

  describe "as an admin" do
    setup :log_in_admin

    test "lists contact messages and deletes one", %{conn: conn} do
      {:ok, message} =
        Outreach.submit_contact_message(%{
          "name" => "Jane",
          "email" => "jane@example.com",
          "message" => "Do you sell milkweed?"
        })

      {:ok, lv, html} = live(conn, ~p"/admin/contact-messages")
      assert html =~ "Do you sell milkweed?"
      assert html =~ "jane@example.com"

      lv |> element("#messages-#{message.id} button", "Delete") |> render_click()

      refute has_element?(lv, "#messages-#{message.id}")
      assert Outreach.list_contact_messages(@admin) == []
    end

    test "lists newsletter signups and removes one", %{conn: conn} do
      {:ok, sub} = Outreach.subscribe(%{"name" => "Sam", "email" => "sam@example.com"})

      {:ok, lv, html} = live(conn, ~p"/admin/newsletter")
      assert html =~ "sam@example.com"

      lv |> element("#subscribers-#{sub.id} button", "Remove") |> render_click()

      refute has_element?(lv, "#subscribers-#{sub.id}")
      assert Outreach.list_subscribers(@admin) == []
    end

    test "dashboard links to both pages with counts", %{conn: conn} do
      {:ok, _} = Outreach.subscribe(%{"email" => "sam@example.com"})
      {:ok, lv, _html} = live(conn, ~p"/admin")

      assert has_element?(lv, ~s(a[href="/admin/contact-messages"]))
      assert has_element?(lv, ~s(a[href="/admin/newsletter"]), "1")
    end
  end
end
