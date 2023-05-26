defmodule WorkspaceExTest do
  use ExUnit.Case
  doctest WorkspaceEx

  test "greets the world" do
    assert WorkspaceEx.hello() == :world
  end
end
