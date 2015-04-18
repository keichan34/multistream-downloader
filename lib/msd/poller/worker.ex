defmodule MSD.Poller.Worker do
  use GenServer

  @doc """
  Starts the worker.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      endpoint: opts[:endpoint]
    ], opts)
  end

  ## Server Callbacks

  # 15 seconds.
  @poll_interval 15000

  def init(opts) do
    Kernel.send self(), :poll_tick
    {:ok, %{endpoint: opts[:endpoint], timer: nil}}
  end

  def handle_info(:poll_tick, state) do
    state = state |>
      do_poll |>
      enqueue_tick

    {:noreply, state}
  end

  defp enqueue_tick(state) do
    timer_ref = Process.send_after self(), :poll_tick, @poll_interval

    %{state | timer: timer_ref}
  end

  defp do_poll(state) do
    IO.puts "Checking #{state[:endpoint]}..."

    state
  end
end
