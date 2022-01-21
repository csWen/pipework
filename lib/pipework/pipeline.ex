defmodule Pipework.Pipeline do
  @type t :: %__MODULE__{
          pipes: [Pipework.Executable.t()],
          hooks: [Pipework.Hook.hook()]
        }

  @callback pipeline() :: t()

  @enforce_keys [:pipes]
  defstruct pipes: [], hooks: []

  defmacro __using__(_opts) do
    quote location: :keep do
      import unquote(__MODULE__), only: [pipe: 1, pipe: 2]

      Module.register_attribute(__MODULE__, :pipes, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro pipe(module, opts \\ []) do
    quote location: :keep do
      @pipes {unquote(module), unquote(opts)}
    end
  end

  defmacro __before_compile__(env) do
    pipes =
      env.module
      |> Module.get_attribute(:pipes)
      |> Enum.map(fn {pipe, opts} ->
        {hooks, opts} = Keyword.pop(opts, :hooks, [])
        %Pipework.Pipe{pipe: pipe, hooks: hooks, opts: opts}
      end)
      |> Enum.reverse()

    pipeline = %Pipework.Pipeline{pipes: pipes}

    quote location: :keep do
      def pipeline, do: unquote(Macro.escape(pipeline))
    end
  end
end

defimpl Pipework.Executable, for: Pipework.Pipeline do
  def exec(%Pipework.Pipeline{pipes: pipes}, context) do
    Enum.reduce_while(pipes, context, fn pipe, context ->
      case Pipework.PipeExecutor.exec(pipe, context) do
        %Pipework.Context{status: :halt} = context ->
          {:halt, context}

        %Pipework.Context{status: :break} = context ->
          {:halt, %{context | status: :running}}

        %Pipework.Context{} = context ->
          {:cont, context}
      end
    end)
  end

  def hooks(%Pipework.Pipeline{hooks: hooks}), do: hooks
end
