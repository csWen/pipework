defmodule Pipework.Pipe do
  @moduledoc """
      +-------+
  --->| pipe1 +--->
      +-------+
  """
  @type t :: %__MODULE__{
          pipe: atom(),
          hooks: [Pipework.Hook.t()],
          opts: Pipework.opts()
        }

  @callback call(Pipework.Context.t(), Pipework.opts()) :: Pipework.Context.t()

  @enforce_keys [:pipe]
  defstruct pipe: nil, hooks: [], opts: []
end

defimpl Pipework.Executable, for: Pipework.Pipe do
  def exec(%Pipework.Pipe{pipe: pipe, opts: opts}, context) do
    pipe.call(context, opts)
  end

  def hooks(%Pipework.Pipe{hooks: hooks}), do: hooks
end
