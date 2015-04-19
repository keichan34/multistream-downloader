defmodule MSD.Watcher.Worker do
  use GenServer

  import HTTPoison, only: [get: 3]

  @doc """
  Timeout of the HTTP connection in ms. Default 1000ms (1s)
  """
  @timeout 1000

  @doc """
  Starts the worker.
  """
  def start_link(%{uri: _, identifier: _} = state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  ## Server Callbacks

  # 15 seconds.
  @poll_interval 15000

  def init(state) do
    Kernel.send self(), :poll_tick
    {:ok, %{uri: state[:uri], timer: nil, downloader: nil, downloader_monitor: nil,
      identifier: state[:identifier], poller_ref: nil}}
  end

  def handle_info(:poll_tick, state) do
    state = state |>
      do_poll

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, :normal}, state) do
    if pid == state[:downloader] do
      state = %{state | downloader: nil, downloader_monitor: nil} |>
        enqueue_tick
    end

    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200}, state) do
    state = state \
      |> stop_async
      |> handle_success

    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: code},
    state) when code >= 300 and code <= 399 do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncHeaders{headers: headers}, state) do
    if new_uri = headers["Location"] do
      IO.puts "[#{state[:identifier]}] #{state[:uri]} => #{new_uri}"

      state = %{state | uri: new_uri} \
        |> stop_async
        |> do_poll
    end

    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{}, state) do
    state = state \
      |> stop_async
      |> handle_error

    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: data}, state) do
    IO.puts "[#{state[:identifier]}] warn: poller received #{byte_size data} bytes."
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncEnd{id: ref}, state) do
    if state[:poller_ref] == ref do
      state = %{state | poller_ref: nil}
    end

    {:noreply, state}
  end

  defp enqueue_tick(%{downloader: nil, poller_ref: nil} = state) do
    timer_ref = Process.send_after self(), :poll_tick, @poll_interval

    %{state | timer: timer_ref}
  end

  defp do_poll(state) do
    IO.puts "[#{state[:identifier]}] Checking..."

    case get(state[:uri], [], timeout: @timeout, stream_to: self) do
      {:ok, %HTTPoison.AsyncResponse{id: ref}} ->
        %{state | poller_ref: ref}
      _ ->
        handle_error(state)
    end
  end

  defp handle_error(state) do
    IO.puts "[#{state[:identifier]}] Down!"
    state
      |> enqueue_tick
  end

  defp handle_success(state) do
    IO.puts "[#{state[:identifier]}] Up!"
    {:ok, downloader_pid} = MSD.Downloader.Supervisor.start_download(
      state[:uri], state[:identifier])

    %{state | downloader: downloader_pid,
              downloader_monitor: Process.monitor(downloader_pid)}
  end

  defp stop_async(%{poller_ref: ref} = state) do
    :hackney.stop_async ref
    :hackney.close ref
    %{state | poller_ref: nil}
  end
end
