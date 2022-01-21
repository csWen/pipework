defmodule Pipework.TaskPipe do
  @moduledoc false

  @type t :: %__MODULE__{
          task_pipe: atom(),
          task_executor: atom(),
          opts: Pipework.opts()
        }

  @callback generate(Pipework.Context.t(), Pipework.opts()) ::
              [{Pipework.Executable.t(), Pipework.Context.t()}]

  @callback collect(Pipework.Context.t(), [Pipework.Context.t()], Pipework.opts()) ::
              Pipework.Context.t()

  @enforce_keys [:task_pipe]
  defstruct task_pipe: nil, opts: [], task_executor: nil
end

defimpl Pipework.Executable, for: Pipework.TaskPipe do
  def exec(
        %Pipework.TaskPipe{
          task_pipe: task_pipe,
          task_executor: task_executor,
          opts: opts
        },
        context
      ) do
    case task_pipe.generate(context, opts) do
      tasks when is_list(tasks) ->
        task_executor = task_executor || Pipework.TaskExecutor.Naive
        contexts = task_executor.exec(tasks, opts)
        task_pipe.collect(context, contexts, opts)

      other ->
        raise "#{task_pipe}.generate/1 should return a list for tasks, got #{inspect(other)}"
    end
  end

  def hooks(_), do: []
end
