defmodule MultistreamDownloader.Downloader.Worker do
  use GenServer

  @doc """
  Starts the worker.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Server Callbacks

  # One minute.
  @poll_interval 15000

  def init(:ok) do
    Process.send_after self(), :poll_tick, @poll_interval
    {:ok, HashDict.new}
  end

  def handle_info(:poll_tick, state) do
    IO.puts "Tick..."
    Process.send_after self(), :poll_tick, @poll_interval
    {:noreply, state}
  end
end
