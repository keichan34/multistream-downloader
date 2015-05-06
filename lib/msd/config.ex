defmodule MSD.Config do
  defmacro __using__(_) do
    quote do
      import MSD.Config, only: [stream: 2]
    end
  end

  defmacro stream(uri, opts) do
    quote do
      MSD.Supervisor.start_watcher unquote(uri), unquote(opts)
    end
  end

  def read!(file) do
    {config, binding} = Code.eval_file(file)
    IO.puts inspect(config)
    IO.puts inspect(binding)
  end
end
