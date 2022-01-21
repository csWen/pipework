defmodule PipeworkTest do
  use ExUnit.Case
  doctest Pipework

  test "greets the world" do
    assert Pipework.hello() == :world
  end
end
