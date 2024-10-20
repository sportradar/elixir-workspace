defmodule Cascade.UtilsTest do
  use ExUnit.Case

  test "implements_behaviour?/2" do
    assert Cascade.Utils.implements_behaviour?(Cascade.Templates.Template, Cascade.Template)

    refute Cascade.Utils.implements_behaviour?(Cascade, Cascade.Template)
  end
end
