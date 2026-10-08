defmodule ShelleyPlants.TurnstileTest do
  # Not async: some tests change the :turnstile app config.
  use ExUnit.Case, async: false

  alias ShelleyPlants.Turnstile

  defp stub_siteverify(response) do
    Req.Test.stub(Turnstile, &Req.Test.json(&1, response))
  end

  defp with_hostnames(hostnames) do
    original = Application.get_env(:shelley_plants, :turnstile)
    Application.put_env(:shelley_plants, :turnstile, Keyword.put(original, :hostnames, hostnames))
    on_exit(fn -> Application.put_env(:shelley_plants, :turnstile, original) end)
  end

  test "sends the token, secret and visitor IP to Cloudflare" do
    Req.Test.stub(Turnstile, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = URI.decode_query(body)
      assert params["response"] == "good-token"
      assert params["remoteip"] == "1.2.3.4"
      assert params["secret"] != ""
      Req.Test.json(conn, %{"success" => true})
    end)

    assert Turnstile.verify("good-token", "contact", "1.2.3.4") == :ok
  end

  test "rejects a token Cloudflare refuses" do
    stub_siteverify(%{"success" => false, "error-codes" => ["invalid-input-response"]})
    assert Turnstile.verify("bad-token", "contact") == {:error, :rejected}
  end

  test "rejects missing or oversized tokens without calling Cloudflare" do
    assert Turnstile.verify(nil, "contact") == {:error, :invalid_token}
    assert Turnstile.verify("", "contact") == {:error, :invalid_token}
    assert Turnstile.verify(String.duplicate("a", 2049), "contact") == {:error, :invalid_token}
  end

  test "fails closed when Cloudflare can't be reached" do
    Req.Test.stub(Turnstile, &Req.Test.transport_error(&1, :timeout))
    assert Turnstile.verify("token", "contact") == {:error, :unavailable}
  end

  describe "with allowed hostnames configured" do
    setup do
      with_hostnames(["biosphere-native-plants.ca"])
    end

    test "accepts a token for the right site and form" do
      stub_siteverify(%{
        "success" => true,
        "hostname" => "biosphere-native-plants.ca",
        "action" => "contact"
      })

      assert Turnstile.verify("token", "contact") == :ok
    end

    test "rejects a token from another site" do
      stub_siteverify(%{"success" => true, "hostname" => "evil.example", "action" => "contact"})
      assert Turnstile.verify("token", "contact") == {:error, :rejected}
    end

    test "rejects a token issued for the other form" do
      stub_siteverify(%{
        "success" => true,
        "hostname" => "biosphere-native-plants.ca",
        "action" => "newsletter"
      })

      assert Turnstile.verify("token", "contact") == {:error, :rejected}
    end
  end
end
