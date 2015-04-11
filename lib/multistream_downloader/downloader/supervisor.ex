defmodule MultistreamDownloader.Downloader.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @worker_name MultistreamDownloader.Downloader.Worker

  def init(:ok) do
    children = [
      worker(MultistreamDownloader.Downloader.Worker,
        [[name: @worker_name]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
