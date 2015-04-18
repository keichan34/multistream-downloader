defmodule MSD.CLI do
  alias MSD.CLI.Shell

  def main(_) do
    start
  end

  defp start do
    MSD.Downloader.Supervisor.start_link
    {:ok, poller} = MSD.Poller.Supervisor.start_link

    MSD.Poller.Supervisor.start_poller(poller,
      "http://www.theincomparable.com:4200/live")
    MSD.Poller.Supervisor.start_poller(poller,
      "http://marco.org:8001/listen")

    Shell.start_synchronous
  end
end
