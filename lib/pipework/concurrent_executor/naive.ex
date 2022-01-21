defmodule Pipework.TaskExecutor.Naive do
  use Pipework.TaskExecutor

  @impl true
  def exec(pipe_and_context_pairs, opts) do
    timeout = Keyword.get(opts, :timeout, 5000)

    pipe_and_context_pairs
    |> Enum.map(fn {pipe, context} ->
      Task.async(fn -> Pipework.PipeExecutor.exec(pipe, context) end)
    end)
    |> Task.await_many(timeout)
  end
end
