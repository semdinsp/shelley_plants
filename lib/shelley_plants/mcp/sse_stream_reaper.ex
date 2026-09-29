defmodule ShelleyPlants.MCP.SseStreamReaper do
  @moduledoc """
  Ends anubis_mcp SSE streams whose client has gone.

  anubis_mcp 2.0.0 leaks one SSE stream process (and its socket) each time a
  client replaces the MCP stream for a session:

    * `Anubis.SSE.Streaming.loop/5` only notices a gone client when a write
      fails, and its only periodic write is the keepalive.
    * `Anubis.Server.Transport.StreamableHTTP` sends `:sse_keepalive` only to
      the handler registered for each session, and replacing that handler
      does not close the old one.

  So a superseded stream never writes again and never exits. Under macOS's
  default limit of 256 open files, this took down the dev node in a sibling
  app (trading_live PR #273).

  Every 30 seconds this process sends every process parked in that loop the
  same `:sse_keepalive` the transport sends. For a gone client the write fails
  within a nudge or two, the loop returns and the socket closes; a live client
  just gets one extra ": keepalive" comment line.

  Remove once anubis_mcp keeps alive every open stream, or closes the old
  stream when a session's handler is replaced.
  """
  use GenServer

  require Logger

  @interval_ms :timer.seconds(30)

  # Far more streams than the handful of MCP clients this app has, so a sign
  # the nudges aren't ending them.
  @warn_at 50

  @stream_loop {Anubis.SSE.Streaming, :loop, 5}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Nudges every stream process now. Returns how many were nudged. For tests and RPC."
  @spec nudge_now(GenServer.server()) :: non_neg_integer()
  def nudge_now(server \\ __MODULE__), do: GenServer.call(server, :nudge_now)

  @impl true
  def init(opts) do
    state = %{
      interval_ms: Keyword.get(opts, :interval_ms, @interval_ms),
      stream_loop: Keyword.get(opts, :stream_loop, @stream_loop)
    }

    schedule(state.interval_ms)
    {:ok, state}
  end

  @impl true
  def handle_call(:nudge_now, _from, state), do: {:reply, nudge(state), state}

  @impl true
  def handle_info(:nudge, state) do
    nudge(state)
    schedule(state.interval_ms)
    {:noreply, state}
  end

  defp nudge(state) do
    streams = stream_processes(state.stream_loop)
    Enum.each(streams, &send(&1, :sse_keepalive))

    count = length(streams)

    if count >= @warn_at do
      Logger.warning(
        "#{inspect(__MODULE__)}: #{count} MCP SSE stream processes alive; " <>
          "streams to gone clients should end after a nudge or two"
      )
    end

    count
  end

  # Only current_function is read per process: cheap, even on a node with
  # thousands of processes.
  defp stream_processes(stream_loop) do
    Enum.filter(Process.list(), fn pid ->
      pid != self() and Process.info(pid, :current_function) == {:current_function, stream_loop}
    end)
  end

  defp schedule(interval_ms), do: Process.send_after(self(), :nudge, interval_ms)
end
