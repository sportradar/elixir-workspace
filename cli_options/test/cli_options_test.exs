defmodule CliOptionsTest do
  use ExUnit.Case
  doctest CliOptions

  describe "parse/2" do
    test "with no arguments and no required options" do
      schema = []
      argv = []

      {:ok, options} = CliOptions.parse(argv, schema)
      assert options.argv == argv
      assert options.schema == schema
      assert options.args == []
      assert options.extra == []
    end

    test "with extra arguments and no required options" do
      schema = []
      argv = ["--", "--foo", "bar"]

      {:ok, options} = CliOptions.parse(argv, schema)
      assert options.argv == argv
      assert options.schema == schema
      assert options.args == []
      assert options.extra == ["--foo", "bar"]
    end

    test "with extra arguments containing separator" do
      schema = []
      argv = ["--", "--foo", "bar", "--", "-b"]

      {:ok, options} = CliOptions.parse(argv, schema)
      assert options.argv == argv
      assert options.schema == schema
      assert options.args == []
      assert options.extra == ["--foo", "bar", "--", "-b"]
    end

    test "with arguments no options" do
      schema = []
      argv = ["foo.ex", "bar.ex", "baz.ex"]

      {:ok, options} = CliOptions.parse(argv, schema)
      assert options.argv == argv
      assert options.schema == schema
      assert options.args == ["foo.ex", "bar.ex", "baz.ex"]
      assert options.extra == []
    end

    test "with arguments and extra" do
      schema = []
      argv = ["foo.ex", "bar.ex", "--", "-b", "-c"]

      {:ok, options} = CliOptions.parse(argv, schema)
      assert options.argv == argv
      assert options.schema == schema
      assert options.args == ["foo.ex", "bar.ex"]
      assert options.extra == ["-b", "-c"]
    end
  end
end
