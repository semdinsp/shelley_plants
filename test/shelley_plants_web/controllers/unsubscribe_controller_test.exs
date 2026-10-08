defmodule ShelleyPlantsWeb.UnsubscribeControllerTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  alias ShelleyPlants.Accounts.Scope
  alias ShelleyPlants.Outreach

  @admin %Scope{admin?: true}

  setup do
    {:ok, sub} = Outreach.subscribe(%{"email" => "sam@example.com"})
    %{sub: sub, token: Outreach.unsubscribe_token(sub)}
  end

  test "opening the link asks for confirmation and doesn't unsubscribe", %{
    conn: conn,
    token: token
  } do
    html = conn |> get(~p"/newsletter/unsubscribe/#{token}") |> html_response(200)

    assert html =~ "Unsubscribe from our newsletter?"
    assert html =~ "sam@example.com"
    assert html =~ ~s(action="/newsletter/unsubscribe/#{token}")
    assert length(Outreach.list_subscribers(@admin)) == 1
  end

  test "confirming unsubscribes", %{conn: conn, token: token} do
    html = conn |> post(~p"/newsletter/unsubscribe/#{token}") |> html_response(200)

    assert html =~ "You're unsubscribed"
    assert Outreach.list_subscribers(@admin) == []
  end

  test "mail-app one-click unsubscribe works without a CSRF token", %{token: token} do
    # build_conn/0 skips CSRF checks by default; turn them back on.
    conn = Plug.Conn.put_private(build_conn(), :plug_skip_csrf_protection, false)

    conn = post(conn, ~p"/newsletter/unsubscribe/#{token}", %{"List-Unsubscribe" => "One-Click"})

    assert html_response(conn, 200) =~ "You're unsubscribed"
    assert Outreach.list_subscribers(@admin) == []
  end

  test "an already-used link says you're unsubscribed", %{conn: conn, token: token} do
    :ok = Outreach.unsubscribe(token)

    assert conn |> get(~p"/newsletter/unsubscribe/#{token}") |> html_response(200) =~
             "You're unsubscribed"
  end

  test "a bad link shows an error and changes nothing", %{conn: conn} do
    assert conn |> get(~p"/newsletter/unsubscribe/bogus") |> html_response(404) =~
             "isn't valid"

    assert build_conn() |> post(~p"/newsletter/unsubscribe/bogus") |> html_response(404) =~
             "isn't valid"

    assert length(Outreach.list_subscribers(@admin)) == 1
  end
end
