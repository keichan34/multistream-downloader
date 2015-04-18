defmodule MSD.Downloader.Worker do
  use GenServer

  @doc """
  Starts the worker.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [
      uri: opts[:uri]
    ], opts)
  end

  ## Server Callbacks

  def init(opts) do
    IO.puts "Starting download of #{opts[:uri]}..."
    {:ok, %{uri: opts[:uri]}}
  end
end
