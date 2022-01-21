defmodule Pipework.Hook do
  @moduledoc false

  alias Pipework.Context

  @type hook :: {atom(), Keyword.t()} | atom()
  @type next :: (Context.t() -> Context.t())
  @callback call(Context.t(), Pipework.opts(), next()) :: Context.t()

  @spec exec_with_hooks([hook()], Context.t(), next()) :: Context.t()
  def exec_with_hooks(hooks, context, executor) do
    hooks = init_hooks(hooks)

    hooked_executor =
      Enum.reduce(hooks, executor, fn {hook, opts}, acc ->
        fn ctx -> hook.call(ctx, opts, acc) end
      end)

    try do
      hooked_executor.(context)
    catch
      kind, reason ->
        require Logger
        stack = __STACKTRACE__
        Logger.error(Exception.format(kind, reason, stack))
        reason = Exception.normalize(kind, reason, stack)
        {:error, %{kind: kind, reason: reason, stack: stack}}
    end
  end

  defp init_hooks(hooks) do
    hooks
    |> Enum.reverse()
    |> Enum.map(fn
      {hook, opts} -> {hook, hook.init(opts)}
      hook -> {hook, []}
    end)
  end
end
