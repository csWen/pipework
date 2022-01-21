defmodule Pipework do
  @moduledoc false

  alias Pipework.{BranchPipe, Context, PipeExecutor, Pipe, Pipeline, TaskPipe}

  @type opts ::
          binary
          | tuple
          | atom
          | integer
          | float
          | [opts]
          | %{optional(opts) => opts}
          | MapSet.t()

  def run(%Pipework.Context{status: :pending} = context, pipes) do
    run(%{context | status: :running}, pipes)
  end

  def run(%Pipework.Context{} = context, []) do
    %{context | status: :done}
  end

  def run(%Pipework.Context{status: :halt} = context, _pipes) do
    context
  end

  def run(%Pipework.Context{} = context, [pipe | pipes]) do
    executable_pipe = get_executable_pipe(pipe)

    case PipeExecutor.exec(executable_pipe, context) do
      %Context{status: :halt} = context ->
        context

      %Context{} = context ->
        run(context, pipes)

      other ->
        raise "expected #{inspect(pipe)} to return Pipework.Context, got: #{inspect(other)}"
    end
  end

  defp get_executable_pipe(%_{} = executable) do
    executable
  end

  defp get_executable_pipe(mod) when is_atom(mod) do
    %Pipe{pipe: mod}
  end

  defp get_executable_pipe({:pipe, mod, opts}) do
    {hooks, opts} = Keyword.pop(opts, :hooks, [])
    %Pipe{pipe: mod, hooks: hooks, opts: opts}
  end

  defp get_executable_pipe({:pipeline, pipes}) when is_list(pipes) do
    get_executable_pipe({:pipeline, pipes, []})
  end

  defp get_executable_pipe({:pipeline, mod}) do
    mod.pipeline()
  end

  defp get_executable_pipe({:pipeline, pipes, opts}) do
    hooks = Keyword.get(opts, :hooks, [])
    pipes = Enum.map(pipes, &get_executable_pipe/1)
    %Pipeline{pipes: pipes, hooks: hooks}
  end

  defp get_executable_pipe({:branch, condition_pipe, branch_pipes}) do
    condition_pipe = get_executable_pipe(condition_pipe)

    branch_pipes =
      branch_pipes
      |> Enum.map(fn {branch, pipe} -> {branch, get_executable_pipe(pipe)} end)
      |> Map.new()

    %BranchPipe{condition_pipe: condition_pipe, branch_pipes: branch_pipes}
  end

  defp get_executable_pipe({:task, task_pipe}) do
    get_executable_pipe({:task, task_pipe, []})
  end

  defp get_executable_pipe({:task, task_pipe, opts}) do
    {task_executor, opts} = Keyword.pop(opts, :task_executor)

    %TaskPipe{task_pipe: task_pipe, opts: opts, task_executor: task_executor}
  end

  defp get_executable_pipe({mod, opts}) do
    {hooks, opts} = Keyword.pop(opts, :hooks, [])
    %Pipe{pipe: mod, hooks: hooks, opts: opts}
  end
end
