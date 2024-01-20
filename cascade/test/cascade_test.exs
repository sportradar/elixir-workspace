defmodule CascadeTest do
  use ExUnit.Case
  doctest Cascade

  test "greets the world" do
    assert Cascade.hello() == :world
  end
end
