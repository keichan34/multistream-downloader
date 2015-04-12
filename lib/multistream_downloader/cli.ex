defmodule MultistreamDownloader.CLI do
  alias MultistreamDownloader.CLI.Shell

  def main(_) do
    start
  end

  defp start do
    MultistreamDownloader.Downloader.Supervisor.start_link
    Shell.start_synchronous
  end
end
