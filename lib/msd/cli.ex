defmodule MSD.CLI do
  def main(_) do
    start
  end

  defp start do
    MSD.Supervisor.start_link
    MSD.Config.read!("./msd_config.exs")

    :timer.sleep(:infinity)
  end
end
