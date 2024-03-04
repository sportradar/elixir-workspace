defmodule CliOptionsTest do
  use ExUnit.Case

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

    test "with option set" do
      schema = [foo: [type: :string]]
      argv = ["--foo", "bar"]

      {:ok, options} = CliOptions.parse(argv, schema)
      assert options.opts == [foo: "bar"]
    end

    test "with option set but specific long name" do
      schema = [user: [type: :string, long: "user_name"]]

      # fails with --user
      {:error, message} = CliOptions.parse(["--user", "john"], schema)
      assert message == "invalid option \"user\""

      # fails with --user-name
      {:error, message} = CliOptions.parse(["--user-name", "john"], schema)
      assert message == "invalid option \"user-name\""

      # must match exactly the long name
      {:ok, options} = CliOptions.parse(["--user_name", "john"], schema)
      assert options.opts == [user: "john"]
    end

    test "with aliases set" do
      schema = [user: [type: :string, long: "user_name", aliases: ["user-name", "user"]]]

      # fails with --user
      {:ok, options} = CliOptions.parse(["--user", "john"], schema)
      assert options.opts == [user: "john"]

      # fails with --user-name
      {:ok, options} = CliOptions.parse(["--user-name", "john"], schema)
      assert options.opts == [user: "john"]

      # must match exactly the long name
      {:ok, options} = CliOptions.parse(["--user_name", "john"], schema)
      assert options.opts == [user: "john"]
    end

    test "with short name set" do
      schema = [user: [type: :string, short: "u"]]

      {:ok, options} = CliOptions.parse(["--user", "john"], schema)
      assert options.opts == [user: "john"]

      {:ok, options} = CliOptions.parse(["-u", "john"], schema)
      assert options.opts == [user: "john"]

      assert {:error, _message} = CliOptions.parse(["-U", "john"], schema)
    end

    test "with short aliases set" do
      schema = [user: [type: :string, short: "u", short_aliases: ["U"]]]

      {:ok, options} = CliOptions.parse(["-u", "john"], schema)
      assert options.opts == [user: "john"]

      {:ok, options} = CliOptions.parse(["-U", "john"], schema)
      assert options.opts == [user: "john"]
    end
  end
end
