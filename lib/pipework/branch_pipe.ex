defmodule Pipework.BranchPipe do
  @moduledoc false

  @type t :: %__MODULE__{
          condition_pipe: Pipework.Executable.t(),
          branch_pipes: %{atom() => Pipework.Executable.t()}
        }

  @enforce_keys [:condition_pipe, :branch_pipes]
  defstruct [:condition_pipe, :branch_pipes]
end

defimpl Pipework.Executable, for: Pipework.BranchPipe do
  def exec(
        %Pipework.BranchPipe{condition_pipe: condition_pipe, branch_pipes: branch_pipes},
        context
      ) do
    case Pipework.PipeExecutor.exec(condition_pipe, context) do
      %Pipework.Context{status: :halt} = context ->
        context

      %Pipework.Context{branch: branch} = context ->
        case Map.get(branch_pipes, branch) do
          nil ->
            raise "branch pipe result can not match any pipe #{inspect(context)}"

          pipe ->
            context = %{context | branch: nil}
            Pipework.PipeExecutor.exec(pipe, context)
        end
    end
  end

  def hooks(_), do: []
end
