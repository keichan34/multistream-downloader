defmodule MSD.Mixfile do
  use Mix.Project

  def project do
    {result, _} = System.cmd("git", ["rev-parse", "HEAD"])
    git_sha = String.slice(result, 0, 7)

    {result, _} = System.cmd("git", ["rev-list", "HEAD", "--count"])
    commit_count = String.strip(result)

    [app: :msd,
     version: "0.0.2-#{commit_count}-#{git_sha}",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: escript_config,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [
        :logger,
        :httpoison,
        :tzdata,
        :timex
      ],
      mod: {MSD, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8"},
      {:timex, "~> 1.0.0"},
      {:exrm, "~> 1.0.0-rc7"}
    ]
  end

  defp escript_config do
    [
      main_module: MSD.CLI,
      name: "msd"
    ]
  end
end
