defmodule MSD.Watcher.Worker do
  use GenServer

  require Logger
  import HTTPoison, only: [get: 3]

  # Timeout of the HTTP connection in ms. Default 1000ms (1s)
  @timeout 1000

  @doc """
  Starts the worker.
  """
  def start_link(%{uri: _, identifier: _} = state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  ## Server Callbacks

  # Maximum poll interval. 300 seconds = 5 minutes.
  @max_poll_interval 300000
  # 2^n - 1 = 300; 2^n = 301; n = log2(301); n = 8.2336196768
  @max_poll_count 9

  def init(state) do
    Kernel.send self(), :poll_tick
    {:ok, %{uri: state[:uri], timer: nil, downloader: nil, downloader_monitor: nil,
      identifier: state[:identifier], poller_ref: nil, polls: 0}}
  end

  def handle_info(:poll_tick, state) do
    state = state |>
      do_poll

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, :normal}, state) do
    state = if pid == state[:downloader] do
      %{state | downloader: nil, downloader_monitor: nil, polls: 0} |>
        enqueue_tick
    else
      state
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
    headers_in_map = Enum.into(headers, %{})
    state = case Map.fetch(headers_in_map, "Location") do
      {:ok, new_uri} ->
        Logger.info "[#{state[:identifier]}] #{state[:uri]} => #{new_uri}"

        %{state | uri: new_uri} \
          |> stop_async
          |> do_poll
      :error ->
        state
    end

    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{}, state) do
    state = state \
      |> stop_async
      |> handle_error

    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncEnd{id: ref}, state) do
    state = if state[:poller_ref] == ref do
      %{state | poller_ref: nil}
    else
      state
    end

    {:noreply, state}
  end

  def handle_info(%HTTPoison.Error{reason: reason}, state) do
    Logger.info "[#{state[:identifier]}] Got socket error: #{reason}"
    state |> enqueue_tick()
  end

  defp enqueue_tick(%{downloader: nil, poller_ref: nil, polls: polls} = state) do
    # Exponential backoff, in 1-second increments.
    int = if polls >= @max_poll_count do
      @max_poll_interval
    else
      (trunc(:math.pow(2, max(polls, 1))) - 1) * 1000
    end

    int = int + :crypto.rand_uniform(-50, 50) * 10

    Logger.info "[#{state[:identifier]}] Will try again in #{Float.round(int / 1000, 1)}s."
    timer_ref = Process.send_after self(), :poll_tick, int

    %{state | timer: timer_ref}
  end

  defp do_poll(%{polls: polls} = state) do
    Logger.info "[#{state[:identifier]}] Checking..."

    state = %{state | polls: polls + 1}

    case get(state[:uri], [], timeout: @timeout, stream_to: self()) do
      {:ok, %HTTPoison.AsyncResponse{id: ref}} ->
        %{state | poller_ref: ref}
      _ ->
        handle_error(state)
    end
  end

  defp handle_error(state) do
    Logger.info "[#{state[:identifier]}] Down!"
    state |> enqueue_tick()
  end

  defp handle_success(state) do
    Logger.info "[#{state[:identifier]}] Up!"
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
