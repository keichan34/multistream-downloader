defmodule MSD.Downloader.Worker do
  use GenServer

  require Logger
  import HTTPoison, only: [get: 3]

  @doc """
  Timeout of the HTTP connection in ms. Default 10,000ms (10s)
  """
  @timeout 10000

  @doc """
  Starts the worker.
  """
  def start_link(%{uri: _, identifier: _} = state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  ## Server Callbacks

  def init(state) do
    Logger.info "[#{state[:identifier]}] Starting download..."
    get state[:uri], [], timeout: @timeout, stream_to: self

    {:ok, %{uri: state[:uri], identifier: state[:identifier], outfile: nil,
      intermediate_filename: nil, result_filename: nil}}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: 200}, state) do
    Logger.info "[#{state[:identifier]}] Started."

    state = create_outfile(state)
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncStatus{code: error}, state) do
    # Ignore an error.
    Logger.info "[#{state[:identifier]}] Got #{error}, exiting."
    {:stop, :normal, state}
  end

  # Ignore headers for now.
  def handle_info(%HTTPoison.AsyncHeaders{headers: _}, state) do
    {:noreply, state}
  end

  def handle_info(%HTTPoison.AsyncChunk{chunk: data}, state) do
    bytes = byte_size data
    Logger.info "[#{state[:identifier]}] Received #{bytes} bytes."

    if bytes == 0 do
      handle_info(%HTTPoison.AsyncEnd{}, state)
    else
      state = write_to_outfile(data, state)
      {:noreply, state}
    end
  end

  def handle_info(%HTTPoison.AsyncEnd{}, state) do
    Logger.info "[#{state[:identifier]}] Finished."
    state = teardown_outfile(state)
    {:stop, :normal, state}
  end

  def handle_info(%HTTPoison.Error{reason: {:closed, reason}}, state) do
    Logger.info "[#{state[:identifier]}] Closed with reason: #{reason}"
    state = teardown_outfile(state)
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.info "[#{state[:identifier]}] Received: #{inspect msg}"
    {:noreply, state}
  end

  ## Internal methods

  defp create_outfile(%{outfile: nil} = state) do
    date = Timex.Date.local
    date_string = Timex.DateFormat.format!(date, "%Y-%m-%d_%H-%M-%S", :strftime)
    filename = "_#{state[:identifier]}_#{date_string}.mp3"
    result_filename = "#{state[:identifier]}_#{date_string}.mp3"
    File.mkdir_p(MSD.out_dir)
    {:ok, file} = File.open MSD.out_dir(filename), [:write]
    %{state | outfile: file, intermediate_filename: filename, result_filename: result_filename}
  end

  defp create_outfile(state), do: state

  defp teardown_outfile(%{outfile: file} = state) do
    if file do
      File.close file
      :file.rename(
        MSD.out_dir(state.intermediate_filename),
        MSD.out_dir(state.result_filename)
      )
      state = %{state | outfile: nil, intermediate_filename: nil, result_filename: nil}
    end
    state
  end

  defp write_to_outfile(bytes, %{outfile: file} = state) do
    IO.binwrite file, bytes
    state
  end
end
