defmodule MSD.Watcher.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_poller(uri) do
    Supervisor.start_child(__MODULE__, [[uri: uri]])
  end

  def init(:ok) do
    children = [
      worker(MSD.Watcher.Worker, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
