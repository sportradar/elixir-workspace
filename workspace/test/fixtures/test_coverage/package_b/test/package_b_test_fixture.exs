defmodule PackageBTest do
  use ExUnit.Case
  doctest PackageB

  test "greets the world" do
    assert PackageB.hello() == :world
  end
end
