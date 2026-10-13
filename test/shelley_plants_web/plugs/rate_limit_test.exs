defmodule ShelleyPlantsWeb.Plugs.RateLimitTest do
  use ShelleyPlantsWeb.ConnCase, async: true

  alias ShelleyPlantsWeb.Plugs.RateLimit

  # A unique fake IP per test, so tests don't share counters
  defp unique_ip, do: "test-ip-#{System.unique_integer([:positive])}"

  defp request(ip) do
    build_conn()
    |> put_req_header("fly-client-ip", ip)
    |> RateLimit.call(RateLimit.init(bucket: :test_bucket))
  end

  test "allows requests up to the limit, then responds 429 with Retry-After" do
    ip = unique_ip()

    for _ <- 1..3, do: refute(request(ip).halted)

    conn = request(ip)
    assert conn.halted
    assert conn.status == 429
    assert [retry_after] = get_resp_header(conn, "retry-after")
    assert String.to_integer(retry_after) in 1..3600
    assert Jason.decode!(conn.resp_body)["error"] == "rate_limited"
  end

  test "counts each IP separately" do
    a = unique_ip()

    for _ <- 1..3, do: request(a)
    assert request(a).status == 429
    refute request(unique_ip()).halted
  end
end
