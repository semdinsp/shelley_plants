defmodule ShelleyPlants.RateLimiter do
  @moduledoc """
  Fixed-window request counting in ETS, for simple per-IP rate limits
  (see `ShelleyPlantsWeb.Plugs.RateLimit`). No external dependency.

  This process owns the table and clears out finished windows every minute.
  Counts are per node, which is fine for one or two Fly machines.
  """
  use GenServer

  @table :shelley_plants_rate_limits
  @cleanup_interval :timer.minutes(1)

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Counts one hit for `key` in the current `window_seconds` window. Returns
  `{:allow, count}` while the count is within `limit`, otherwise
  `{:deny, seconds_until_the_window_resets}`.
  """
  def hit(key, limit, window_seconds) do
    now = System.system_time(:second)
    window = div(now, window_seconds)
    entry = {key, window_seconds, window}
    count = :ets.update_counter(@table, entry, 1, {entry, 0})

    if count <= limit,
      do: {:allow, count},
      else: {:deny, (window + 1) * window_seconds - now}
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    schedule_cleanup()
    {:ok, nil}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.system_time(:second)

    # Delete counters whose window has ended
    :ets.select_delete(@table, [
      {{{:_, :"$1", :"$2"}, :_}, [{:<, {:*, {:+, :"$2", 1}, :"$1"}, now}], [true]}
    ])

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup, do: Process.send_after(self(), :cleanup, @cleanup_interval)
end
