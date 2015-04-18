defmodule MSD.Downloader.Worker do
  use GenServer

  import HTTPoison, only: [get: 3]

  @doc """
  Timeout of the HTTP connection in ms. Default 1000ms (1s)
  """
  @timeout 1000

  @doc """
  Starts the worker.
  """
  def start_link(%{uri: _, save_to: _} = state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  ## Server Callbacks

  def init(opts) do
    IO.puts "Starting download of #{opts[:uri]}..."
    get opts[:uri], [], timeout: @timeout, stream_to: self

    {:ok, %{uri: opts[:uri], save_to: opts[:save_to]}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200}, state) do
    IO.puts "Started download."
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: error}, state) do
    # Ignore an error.
    IO.puts "Got #{error}, exiting."
    {:stop, :normal, state}
  end

  # Ignore headers for now.
  def handle_info(%HTTPoison.AsyncHeaders{headers: _}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: data}, state) do
    IO.puts "Got a chunk (#{byte_size data}b)."
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncEnd{}, state) do
    IO.puts "Finished #{state[:uri]}."
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    IO.puts "Received: #{inspect msg}"
    {:noreply, state}
  end
end
