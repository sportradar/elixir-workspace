defmodule PackageCTest do
  use ExUnit.Case
  doctest PackageC

  test "greets the world" do
    assert PackageC.hello() == :world
  end
end
