defmodule Cascade.ChecksTest do
  use ExUnit.Case

  test "check_module_name_validity!/1" do
    assert Cascade.Checks.check_module_name_validity!("Foo")
    assert Cascade.Checks.check_module_name_validity!("Foo.Bar")
    assert Cascade.Checks.check_module_name_validity!("Foo.Bar_Baz")

    assert_raise ArgumentError,
                 "Module name must be a valid Elixir alias (for example: Foo.Bar), got: \"123\"",
                 fn -> Cascade.Checks.check_module_name_validity!("123") end

    assert_raise ArgumentError,
                 "Module name must be a valid Elixir alias (for example: Foo.Bar), got: \"Foo.Bar#\"",
                 fn -> Cascade.Checks.check_module_name_validity!("Foo.Bar#") end
  end

  test "check_module_name_availability!/1" do
    assert Cascade.Checks.check_module_name_availability!("Foo")
    assert Cascade.Checks.check_module_name_availability!("Foo.Bar")
    assert Cascade.Checks.check_module_name_availability!("Foo.Bar_Baz")

    assert_raise ArgumentError,
                 "Module name Cascade is already taken, please choose another name",
                 fn -> Cascade.Checks.check_module_name_availability!("Cascade") end
  end

  test "check_directory_existence!/1" do
    message = "Directory #{File.cwd!()} exists already."

    assert_raise ArgumentError,
                 message,
                 fn -> Cascade.Checks.check_directory_existence!(File.cwd!()) end

    assert Cascade.Checks.check_directory_existence!(Path.join(File.cwd!(), "foo"))
  end
end
