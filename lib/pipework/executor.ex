defprotocol Pipework.Executable do
  @moduledoc false

  @spec exec(__MODULE__.t(), Pipework.Context.t()) :: Pipework.Context.t()
  def exec(executable, context)

  @spec hooks(__MODULE__.t()) :: [Pipework.Hook.hook()]
  def hooks(executable)
end

defmodule Pipework.PipeExecutor do
  alias Pipework.{Executable, Hook}

  def exec(executable, context) do
    case Executable.hooks(executable) do
      [] ->
        Executable.exec(executable, context)

      hooks ->
        executor = fn context -> Executable.exec(executable, context) end
        Hook.exec_with_hooks(hooks, context, executor)
    end
  end
end

defmodule Pipework.TaskExecutor do
  @moduledoc false

  @callback exec([{Pipework.Executable.t(), Pipework.Context.t()}], Keyword.t()) :: [
              Pipework.Context.t()
            ]

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end
end
