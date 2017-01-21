defmodule MSD do
  use Application

  def start(_type, _args) do
    root_sup = {:ok, _} = MSD.Supervisor.start_link
    if config_file() do
      MSD.Config.read!(config_file())
    end
    root_sup
  end

  def config_file,
    do: Application.get_env(:msd, :config_file)

  def out_dir,
    do: Application.get_env(:msd, :out)
  def out_dir(other),
    do: Path.join(out_dir(), other)
end
