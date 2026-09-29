defmodule ShelleyPlants.MCP.SseStreamReaperTest do
  use ExUnit.Case, async: true

  alias ShelleyPlants.MCP.SseStreamReaper

  # Stands in for Anubis.SSE.Streaming.loop/5: parks in receive, like a
  # stream waiting for its next message, and reports each keepalive.
  defmodule FakeStream do
    def loop(parent) do
      receive do
        :sse_keepalive ->
          send(parent, {:keepalive, self()})
          loop(parent)
      end
    end
  end

  @fake_loop {FakeStream, :loop, 1}

  defp start_reaper(opts \\ []) do
    start_supervised!(
      {SseStreamReaper,
       Keyword.merge([name: nil, stream_loop: @fake_loop, interval_ms: :timer.hours(1)], opts)}
    )
  end

  defp start_stream do
    parent = self()
    pid = spawn_link(fn -> FakeStream.loop(parent) end)
    # Wait until it's parked in the loop, so the reaper can see it.
    wait_until(fn -> Process.info(pid, :current_function) == {:current_function, @fake_loop} end)
    pid
  end

  defp wait_until(fun, tries \\ 50) do
    cond do
      fun.() -> :ok
      tries == 0 -> flunk("condition not met")
      true -> Process.sleep(10) && wait_until(fun, tries - 1)
    end
  end

  test "nudges every process parked in the stream loop with :sse_keepalive" do
    reaper = start_reaper()
    a = start_stream()
    b = start_stream()

    assert SseStreamReaper.nudge_now(reaper) == 2
    assert_receive {:keepalive, ^a}
    assert_receive {:keepalive, ^b}
  end

  test "leaves processes that aren't in the stream loop alone" do
    reaper = start_reaper()
    other = spawn_link(fn -> receive do: (_ -> send(self(), :never)) end)

    assert SseStreamReaper.nudge_now(reaper) == 0
    assert Process.alive?(other)
    refute_receive {:keepalive, _}
  end

  test "nudges on its own every interval" do
    stream = start_stream()
    start_reaper(interval_ms: 20)

    assert_receive {:keepalive, ^stream}, 500
    assert_receive {:keepalive, ^stream}, 500
  end
end
