defmodule MSD.CLI do
  alias MSD.CLI.Shell

  def main(_) do
    start
  end

  defp start do
    MSD.Supervisor.start_link

    MSD.Supervisor.start_poller(
      "http://www.theincomparable.com:4200/live")
    MSD.Supervisor.start_poller(
      "http://marco.org:8001/listen")

    Shell.start_synchronous
  end
end
