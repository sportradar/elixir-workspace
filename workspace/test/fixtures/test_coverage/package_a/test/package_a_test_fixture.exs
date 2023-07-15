defmodule PackageATest do
  use ExUnit.Case
  doctest PackageA

  test "greets the world" do
    assert PackageA.hello() == :world
  end
end
