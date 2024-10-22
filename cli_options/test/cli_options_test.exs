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
    end

    test "multiple with separator set" do
      # without separator used
      schema = [project: [type: :string, short: "p", multiple: true, separator: ","]]

      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["-p", "foo", "-p", "bar"], schema)

      assert opts == [project: ["foo", "bar"]]

      # passed with a separator once
      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["-p", "foo,bar"], schema)

      assert opts == [project: ["foo", "bar"]]

      # passed multiple times with separators
      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["-p", "foo,bar", "-p", "baz", "-p", "ban,buzz"], schema)

      assert opts == [project: ["foo", "bar", "baz", "ban", "buzz"]]

      # all passed options are casted if needed
      schema = [number: [type: :integer, multiple: true, short: "n", separator: ","]]

      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["--number", "3", "-n", "2,1"], schema)

      assert opts == [number: [3, 2, 1]]

      # error if any option is not the proper type
      assert {:error, message} =
               CliOptions.parse(["--number", "3", "-n", "2,1a"], schema)

      assert message == ":number expected an integer argument, got: 1a"
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

    test "with post_validate set" do
      schema = [project: [type: :string, multiple: true], name: [type: :string]]

      post_validate = fn {opts, args, extra} ->
        cond do
          opts[:project] != [] and is_nil(opts[:name]) ->
            {:error, "name must be set if project set"}

          true ->
            {:ok, {Keyword.put(opts, :foo, 1), args, extra}}
        end
      end

      assert {:error, message} =
               CliOptions.parse(["--project", "foo"], schema, post_validate: post_validate)

      assert message == "name must be set if project set"

      assert {:ok, {opts, [], []}} =
               CliOptions.parse(["--project", "foo", "--name", "name"], schema,
                 post_validate: post_validate
               )

      assert opts == [foo: 1, project: ["foo"], name: "name"]
    end

    test "error if post_validate is not a function" do
      schema = [project: [type: :string]]

      assert {:error, message} =
               CliOptions.parse(["--project", "foo"], schema, post_validate: :invalid)

      assert message == "expected :post_validate to be a function of arity 1, got: :invalid"
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

  describe ":deprecated" do
    import ExUnit.CaptureIO

    test "warns when given deprecated argument is given" do
      schema = [
        foo: [deprecated: "use --bar"],
        verbose: [type: :boolean, short: "v", deprecated: "do not use"]
      ]

      captured =
        capture_io(:stderr, fn ->
          options = CliOptions.parse!(["--foo", "value", "-v"], schema)

          assert options == {[foo: "value", verbose: true], [], []}
        end)

      assert captured =~ "--foo is deprecated, use --bar"
      assert captured =~ "-v is deprecated, do not use"
    end

    test "does not warn when not given" do
      schema = [context: [deprecated: "Use something else"]]

      assert capture_io(:stderr, fn ->
               options = CliOptions.parse!([], schema)

               assert options == {[], [], []}
             end) == ""
    end
  end

  describe ":env set" do
    @env_schema [
      name: [type: :string, env: "TEST_NAME", required: true],
      age: [type: :integer, env: "TEST_AGE"],
      enable: [type: :boolean, env: "TEST_ENABLE"]
    ]

    setup do
      on_exit(fn ->
        System.delete_env("TEST_NAME")
        System.delete_env("TEST_AGE")
        System.delete_env("TEST_ENABLE")
      end)
    end

    test "env vars are ignored if user provides the cli args" do
      System.put_env("TEST_NAME", "foo")
      System.put_env("TEST_AGE", "13")

      assert {opts, [], []} = CliOptions.parse!(["--name", "bar", "--age", "20"], @env_schema)
      assert opts == [name: "bar", age: 20, enable: false]
    end

    test "env vars are used if not set in options" do
      System.put_env("TEST_NAME", "foo")
      System.put_env("TEST_AGE", "13")

      assert {opts, [], []} = CliOptions.parse!(["--enable"], @env_schema)
      assert opts == [name: "foo", age: 13, enable: true]
    end

    test "env vars types are validated" do
      System.put_env("TEST_NAME", "foo")
      System.put_env("TEST_AGE", "invalid")

      assert CliOptions.parse(["--enable"], @env_schema) ==
               {:error, ":age expected an integer argument, got: invalid"}
    end

    test "env vars truthy values" do
      for value <- ["1", "true", "TRUE", "tRuE"] do
        System.put_env("TEST_ENABLE", value)

        assert {opts, [], []} = CliOptions.parse!(["--name", "foo"], @env_schema)
        assert opts[:enable]
      end

      for value <- ["0", "false", "other"] do
        System.put_env("TEST_ENABLE", value)

        assert {opts, [], []} = CliOptions.parse!(["--name", "foo"], @env_schema)
        refute opts[:enable]
      end
    end

    test "env vars casing definition does not matter" do
      System.put_env("TEST_NAME", "foo")

      assert CliOptions.parse!([], name: [type: :string, env: "TEST_NAME"]) ==
               {[name: "foo"], [], []}

      assert CliOptions.parse!([], name: [type: :string, env: "test_name"]) ==
               {[name: "foo"], [], []}

      assert CliOptions.parse!([], name: [type: :string, env: "Test_NAMe"]) ==
               {[name: "foo"], [], []}
    end
  end
end
