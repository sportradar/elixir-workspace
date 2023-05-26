defmodule CliOptsTest do
  use ExUnit.Case
  doctest CliOpts

  test "greets the world" do
    assert CliOpts.hello() == :world
  end
end
