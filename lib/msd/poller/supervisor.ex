defmodule MSD.Poller.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def start_poller(supervisor, endpoint) do
    Supervisor.start_child(supervisor, [[endpoint: endpoint]])
  end

  def init(:ok) do
    children = [
      worker(MSD.Poller.Worker, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
