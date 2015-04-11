defmodule MultistreamDownloader.CLI do
  def main(argv) do
    argv
      |> parse_args
      |> process
  end

  defp parse_args(argv) do
    parse = OptionParser.parse(argv,
      switches: [ help:  :boolean,
                  start: :boolean ],
      aliases:  [ h:     :help,
                  s:     :start   ])

    case parse do
      { [help: true], _, _} ->
        :help
      { [start: true], _, _} ->
        :start
      _ -> :help
    end
  end

  defp process(:help) do
    IO.puts """
    usage: msd [options]
    """
  end

  defp process(:start) do
    MultistreamDownloader.Downloader.Supervisor.start_link
    :timer.sleep(:infinity)
  end
end
