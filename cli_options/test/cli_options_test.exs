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

    test "by default undersores in long names are mapped to hyphens" do
      schema = [user_name: [type: :string]]

      {:ok, options} = CliOptions.parse(["--user-name", "john"], schema)
      assert options.opts == [user_name: "john"]

      assert {:error, _message} = CliOptions.parse(["--user_name", "john"], schema)
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

    test "error with multi-letter alias" do
      {:error, message} = CliOptions.parse(["-uv", "john"], [])
      assert message == "an option alias must be one character long, got: \"uv\""
    end

    test "with integer options" do
      schema = [partition: [type: :integer]]

      {:ok, options} = CliOptions.parse(["--partition", "1"], schema)
      assert options.opts == [partition: 1]

      {:error, message} = CliOptions.parse(["--partition", "1f"], schema)
      assert message == ":partition expected an integer argument, got: 1f"
    end

    test "with float options" do
      schema = [weight: [type: :float]]

      {:ok, options} = CliOptions.parse(["--weight", "1"], schema)
      assert options.opts == [weight: 1.0]

      {:ok, options} = CliOptions.parse(["--weight", "1.5"], schema)
      assert options.opts == [weight: 1.5]

      {:error, message} = CliOptions.parse(["--weight", "bar"], schema)
      assert message == ":weight expected a float argument, got: bar"
    end

    test "with boolean options" do
      schema = [verbose: [type: :boolean], dry_run: [type: :boolean]]

      {:ok, options} = CliOptions.parse(["--verbose", "1"], schema)
      assert options.opts == [verbose: true]
      assert options.args == ["1"]

      {:ok, options} = CliOptions.parse(["--verbose", "1", "--dry-run", "2"], schema)
      assert options.opts == [verbose: true, dry_run: true]
      assert options.args == ["1", "2"]
    end

    test "with default values" do
      schema = [
        file: [type: :string, default: "mix.exs"],
        runs: [type: :integer, default: 2],
        verbose: [type: :boolean]
      ]

      {:ok, options} = CliOptions.parse(["foo", "bar"], schema)
      assert options.opts == [file: "mix.exs", runs: 2]
      assert options.args == ["foo", "bar"]

      {:ok, options} = CliOptions.parse(["--runs", "1", "--verbose", "foo", "bar"], schema)
      assert options.opts == [file: "mix.exs", runs: 1, verbose: true]
      assert options.args == ["foo", "bar"]
    end
  end

  describe "parse!/2" do
    test "raises in case of error" do
      assert_raise CliOptions.ParseError, "invalid option \"foo\"", fn ->
        CliOptions.parse!(["--foo"], [])
      end
    end

    test "returns options if successful" do
      options = CliOptions.parse!(["--foo", "bar"], foo: [type: :string])

      assert %CliOptions.Options{} = options
      assert options.opts == [foo: "bar"]
    end
  end
end
