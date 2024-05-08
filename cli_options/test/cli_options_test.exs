defmodule CliOptionsTest do
  use ExUnit.Case

  doctest CliOptions

  describe "parse/2" do
    test "with no arguments and no required options" do
      schema = []
      argv = []

      assert {:ok, {[], [], []}} = CliOptions.parse(argv, schema)
    end

    test "with extra arguments and no required options" do
      schema = []
      argv = ["--", "--foo", "bar"]

      assert {:ok, {[], [], extra}} = CliOptions.parse(argv, schema)
      assert extra == ["--foo", "bar"]
    end

    test "with extra arguments containing separator" do
      schema = []
      argv = ["--", "--foo", "bar", "--", "-b"]

      assert {:ok, {[], [], extra}} = CliOptions.parse(argv, schema)
      assert extra == ["--foo", "bar", "--", "-b"]
    end

    test "with arguments no options" do
      schema = []
      argv = ["foo.ex", "bar.ex", "baz.ex"]

      assert {:ok, {[], args, []}} = CliOptions.parse(argv, schema)
      assert args == ["foo.ex", "bar.ex", "baz.ex"]
    end

    test "with arguments and extra" do
      schema = []
      argv = ["foo.ex", "bar.ex", "--", "-b", "-c"]

      assert {:ok, {[], args, extra}} = CliOptions.parse(argv, schema)
      assert args == ["foo.ex", "bar.ex"]
      assert extra == ["-b", "-c"]
    end

    test "with option set" do
      schema = [foo: [type: :string]]
      argv = ["--foo", "bar"]

      assert {:ok, {opts, [], []}} = CliOptions.parse(argv, schema)
      assert opts == [foo: "bar"]
    end

    test "by default underscores in long names are mapped to hyphens" do
      schema = [user_name: [type: :string]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--user-name", "john"], schema)
      assert opts == [user_name: "john"]
      assert {:error, _message} = CliOptions.parse(["--user_name", "john"], schema)
    end

    test "with value for option missing" do
      schema = [user: [type: :string], verbose: [type: :boolean]]

      # with value not set
      assert {:error, message} = CliOptions.parse(["--user"], schema)
      assert message == ":user expected at least 1 arguments"

      assert {:error, message} = CliOptions.parse(["--user", "--verbose"], schema)
      assert message == ":user expected at least 1 arguments"
    end

    test "with option set but specific long name" do
      schema = [user: [type: :string, long: "user_name"]]

      # fails with --user
      assert {:error, message} = CliOptions.parse(["--user", "john"], schema)
      assert message == "invalid option \"user\""

      # fails with --user-name
      assert {:error, message} = CliOptions.parse(["--user-name", "john"], schema)
      assert message == "invalid option \"user-name\""

      # must match exactly the long name
      assert {:ok, {opts, [], []}} = CliOptions.parse(["--user_name", "john"], schema)
      assert opts == [user: "john"]
    end

    test "with aliases set" do
      schema = [user: [type: :string, long: "user_name", aliases: ["user-name", "user"]]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--user", "john"], schema)
      assert opts == [user: "john"]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--user-name", "john"], schema)
      assert opts == [user: "john"]

      # must match exactly the long name
      assert {:ok, {opts, [], []}} = CliOptions.parse(["--user_name", "john"], schema)
      assert opts == [user: "john"]
    end

    test "long names do not interfer with aliases" do
      schema = [user: [type: :string, long: "u"], update: [type: :boolean, short: "u"]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--u", "john", "-u"], schema)
      assert opts == [user: "john", update: true]
    end

    test "with short name set" do
      schema = [user: [type: :string, short: "u"]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--user", "john"], schema)
      assert opts == [user: "john"]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["-u", "john"], schema)
      assert opts == [user: "john"]

      assert {:error, _message} = CliOptions.parse(["-U", "john"], schema)
    end

    test "with short aliases set" do
      schema = [user: [type: :string, short: "u", short_aliases: ["U"]]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["-u", "john"], schema)
      assert opts == [user: "john"]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["-U", "john"], schema)
      assert opts == [user: "john"]
    end

    test "error with multi-letter alias" do
      assert {:error, message} = CliOptions.parse(["-uv", "john"], [])
      assert message == "an option alias must be one character long, got: \"uv\""
    end

    test "with integer options" do
      schema = [partition: [type: :integer]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--partition", "1"], schema)
      assert opts == [partition: 1]

      assert {:error, message} = CliOptions.parse(["--partition", "1f"], schema)
      assert message == ":partition expected an integer argument, got: 1f"
    end

    test "with float options" do
      schema = [weight: [type: :float]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--weight", "1"], schema)
      assert opts == [weight: 1.0]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--weight", "1.5"], schema)
      assert opts == [weight: 1.5]

      assert {:error, message} = CliOptions.parse(["--weight", "bar"], schema)
      assert message == ":weight expected a float argument, got: bar"
    end

    test "with boolean options" do
      schema = [verbose: [type: :boolean], dry_run: [type: :boolean]]

      assert {:ok, {opts, args, []}} = CliOptions.parse(["--verbose", "1"], schema)
      assert opts == [verbose: true, dry_run: false]
      assert args == ["1"]

      assert {:ok, {opts, args, []}} =
               CliOptions.parse(["--verbose", "1", "--dry-run", "2"], schema)

      assert opts == [verbose: true, dry_run: true]
      assert args == ["1", "2"]
    end

    test "if a boolean is set to a default value of true it is negated" do
      schema = [no_check: [type: :boolean, default: true]]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--no-check"], schema)
      assert opts == [no_check: false]

      assert {:ok, {opts, [], []}} = CliOptions.parse([], schema)
      assert opts == [no_check: true]
    end

    test "with atom options" do
      schema = [mode: [type: :atom], project: [type: :atom, multiple: true]]

      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["--mode", "parallel", "--project", "foo"], schema)

      assert opts == [mode: :parallel, project: [:foo]]

      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["--project", "foo", "--project", "bar"], schema)

      assert opts == [project: [:foo, :bar]]
    end

    test "with allowed values set" do
      schema = [
        mode: [type: :atom, allowed: ["fast", "slow"]]
      ]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--mode", "fast"], schema)
      assert opts == [mode: :fast]

      # with not allowed value
      assert {:error, message} = CliOptions.parse(["--mode", "other"], schema)
      assert message == "invalid value \"other\" for :mode, allowed: [\"fast\", \"slow\"]"
    end

    test "with default values" do
      schema = [
        file: [type: :string, default: "mix.exs"],
        runs: [type: :integer, default: 2],
        verbose: [type: :boolean]
      ]

      assert {:ok, {opts, args, []}} = CliOptions.parse(["foo", "bar"], schema)
      assert opts == [file: "mix.exs", runs: 2, verbose: false]
      assert args == ["foo", "bar"]

      assert {:ok, {opts, args, []}} =
               CliOptions.parse(["--runs", "1", "--verbose", "foo", "bar"], schema)

      assert opts == [file: "mix.exs", runs: 1, verbose: true]
      assert args == ["foo", "bar"]
    end

    test "with required options" do
      schema = [file: [type: :string, required: true]]

      assert {:error, message} = CliOptions.parse([], schema)
      assert message == "option :file is required"

      assert {:ok, {opts, [], []}} = CliOptions.parse(["--file", "mix.exs"], schema)
      assert opts == [file: "mix.exs"]
    end

    test "passing option multiple times" do
      schema = [file: [type: :string]]

      assert {:error, message} =
               CliOptions.parse(["--file", "foo.ex", "--file", "bar.ex"], schema)

      assert message == "option :file has already been set with foo.ex"

      # with multiple set to true we can set multiple values
      schema = [file: [type: :string, multiple: true]]

      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["--file", "foo.ex", "--file", "bar.ex"], schema)

      assert opts == [file: ["foo.ex", "bar.ex"]]

      # with a single item is still a list
      assert {:ok, {opts, [], []}} = CliOptions.parse(["--file", "foo.ex"], schema)
      assert opts == [file: ["foo.ex"]]

      # all passed options are casted if needed
      schema = [number: [type: :integer, multiple: true, short: "n"]]

      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["--number", "3", "-n", "2", "-n", "1"], schema)

      assert opts == [number: [3, 2, 1]]

      # error if any option is not the proper type
      assert {:error, message} =
               CliOptions.parse(["--number", "3", "-n", "2a", "-n", "1"], schema)

      assert message == ":number expected an integer argument, got: 2a"

      # with num_args set
      assert {}
    end

    test "counters" do
      schema = [verbosity: [type: :counter, short: "v"]]

      # if not set it is set to 0
      assert {:ok, {opts, [], []}} = CliOptions.parse([], schema)
      assert opts == [verbosity: 0]

      # counts number of occurrences
      assert {:ok, {opts, [], []}} = CliOptions.parse(["-v", "-v"], schema)
      assert opts == [verbosity: 2]

      assert {:ok, {opts, [], []}} = CliOptions.parse(["-v", "-v", "--verbosity"], schema)
      assert opts == [verbosity: 3]
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

      assert {opts, [], []} = options
      assert opts == [foo: "bar"]

      result =
        CliOptions.parse!(["--foo", "bar", "a", "b", "--", "-n", "2"], foo: [type: :string])

      assert result == {[foo: "bar"], ["a", "b"], ["-n", "2"]}
    end
  end
end
