defmodule MSD.CLI do
  alias MSD.CLI.Shell

  def main(_) do
    start
  end

  defp start do
    MSD.Supervisor.start_link

    MSD.Supervisor.start_watcher(
      "http://www.theincomparable.com:4200/live", "TheIncomparable")
    MSD.Supervisor.start_watcher(
      "http://marco.org:8001/listen", "ATPFM")
    MSD.Supervisor.start_watcher(
      "http://amp.relay.fm:8000/stream", "RelayFM")

    Shell.start_synchronous
  end
end
