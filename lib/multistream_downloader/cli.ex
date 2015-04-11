defmodule MultistreamDownloader.CLI do
  def main(argv) do
    argv
      |> parse_args
      |> process
  end

  defp parse_args(argv) do
    parse = OptionParser.parse(argv,
      switches: [ help: :boolean ],
      aliases:  [ h:    :help    ])

    case parse do
      { [help: true], _, _} ->
        :help
      _ -> :help
    end
  end

  defp process(:help) do
    IO.puts """
    usage: msd [options]
    """
  end
end
