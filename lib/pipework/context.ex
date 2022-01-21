defprotocol Pipework.Context do
  @moduledoc false

  @type t :: %__MODULE__{
          data: any(),
          status: atom(),
          branch: nil | atom(),
          tasks: [(() -> any())],
          task_res: [any()]
        }

  defstruct data: nil, branch: nil, status: :pending, tasks: [], task_res: []
end
