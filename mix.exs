defmodule MSD.Mixfile do
  use Mix.Project

  def project do
    [app: :msd,
     version: "0.0.1",
     elixir: "~> 1.0",
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
      {:httpoison, "~> 0.7.0"},
      {:timex, "~> 0.19.0"},
      {:exrm, "~> 0.19.0"}
    ]
  end

  defp escript_config do
    [
      main_module: MSD.CLI,
      name: "msd"
    ]
  end
end
