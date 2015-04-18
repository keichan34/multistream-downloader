defmodule MSD.CLI.Shell do
  def start_synchronous do
    prompt
  end

  defp prompt do
    IO.gets("> ")
      |> parse_command
      |> process
    prompt
  end

  defp parse_command(:eof) do
    IO.puts("\nExiting.")
    Kernel.exit :normal
  end

  defp parse_command(command) do
    command = String.rstrip(command, ?\n)
    String.split(command, ~r/\s+/)
  end

  defp process(["help"]) do
    IO.puts """
    Nothing to see yet.
    """
  end

  defp process(_) do
    IO.puts """
    Unrecognised command. Please enter 'help' for help.
    """
  end
end
