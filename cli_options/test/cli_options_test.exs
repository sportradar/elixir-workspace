defmodule CliOptionsTest do
  use ExUnit.Case
  doctest CliOptions

  test "greets the world" do
    assert CliOptions.hello() == :world
  end
end
