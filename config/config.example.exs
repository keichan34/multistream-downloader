# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :msd,
  config_file: "./msd_config.exs",
  out: "./msd_out"

config :logger, :console,
  format: "$date $time [$level] $message\n"
