defmodule MSD.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_watcher(uri, identifier) do
    Supervisor.start_child(MSD.Watcher.Supervisor,
      [%{uri: uri, identifier: identifier}])
  end

  def init(:ok) do
    children = [
      supervisor(MSD.Watcher.Supervisor, []),
      supervisor(MSD.Downloader.Supervisor, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
