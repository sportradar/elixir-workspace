defmodule GenifyTest do
  use ExUnit.Case
  doctest Genify

  test "greets the world" do
    assert Genify.hello() == :world
  end
end
