defmodule MSD.Watcher.Worker do
  use GenServer

  import HTTPoison, only: [head: 3]

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
      identifier: state[:identifier]}}
  end

  def handle_info(:poll_tick, state) do
    state = state |>
      do_poll |>
      enqueue_tick

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, pid, :normal}, state) do
    if pid == state[:downloader] do
      state = %{state | downloader: nil, downloader_monitor: nil} |>
        enqueue_tick
    end

    {:noreply, state}
  end

  defp enqueue_tick(%{downloader: nil} = state) do
    timer_ref = Process.send_after self(), :poll_tick, @poll_interval

    %{state | timer: timer_ref}
  end

  defp enqueue_tick(%{downloader: downloader_pid} = state) do
    unless Process.alive?(downloader_pid) do
      %{state | downloader: nil} |> enqueue_tick
    else
      state
    end
  end

  defp do_poll(state) do
    IO.puts "[#{state[:identifier]}] Checking..."

    response = head state[:uri], [], timeout: @timeout
    read_response(response, state)
  end

  defp read_response({:error, %HTTPoison.Error{}}, state) do
    handle_error state
  end

  defp read_response({:ok, %HTTPoison.Response{status_code: 200}}, state) do
    handle_success state
  end

  defp read_response({:ok, %HTTPoison.Response{status_code: code, headers: headers}},
    state) when code >= 300 and code <= 399 do

    if new_uri = headers["Location"] do
      IO.puts "[#{state[:identifier]}] #{state[:uri]} => #{new_uri}"

      state = %{state | uri: new_uri} |>
        do_poll
    end

    state
  end

  defp read_response({:ok, %HTTPoison.Response{}}, state) do
    handle_error state
  end

  defp handle_error(state) do
    IO.puts "[#{state[:identifier]}] Down!"
    state
  end

  defp handle_success(state) do
    IO.puts "[#{state[:identifier]}] Up!"
    {:ok, downloader_pid} = MSD.Downloader.Supervisor.start_download(
      state[:uri], state[:identifier])

    %{state | downloader: downloader_pid,
              downloader_monitor: Process.monitor(downloader_pid)}
  end
end
