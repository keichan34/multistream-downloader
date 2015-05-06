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
    Code.eval_file(file)
  end
end
