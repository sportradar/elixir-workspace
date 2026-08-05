defmodule CliOptions.Schema.ValidatorTest do
  use ExUnit.Case

  alias CliOptions.Schema.Validator

  # notice that the expected messages are built with `inspect/1`, in order to
  # avoid depending on the inspection format of the various elixir versions
  defp type_error(key, expected, value),
    do:
      {:error,
       "invalid value for #{inspect(key)} option: expected #{expected}, got: #{inspect(value)}"}

  describe "validate/2 - invalid input" do
    test "with a non keyword list" do
      for opts <- [1, "foo", :foo, [1, 2], [{:foo, 1}, :bar]] do
        assert Validator.validate(opts, []) ==
                 {:error, "expected a keyword list, got: #{inspect(opts)}"}
      end
    end

    test "an empty keyword list is valid" do
      assert Validator.validate([], []) == {:ok, []}
    end
  end

  describe "validate/2 - unknown keys" do
    test "with an unknown option" do
      assert Validator.validate([foo: 1], []) ==
               {:error, "unknown options [:foo], valid options are: []"}
    end

    test "all unknown options are reported, in the order they were given" do
      schema = [name: [type: :string]]

      assert Validator.validate([foo: 1, name: "x", bar: 2], schema) ==
               {:error, "unknown options [:foo, :bar], valid options are: [:name]"}
    end

    test "unknown options take precedence over invalid values" do
      schema = [name: [type: :string]]

      assert Validator.validate([name: 1, foo: 2], schema) ==
               {:error, "unknown options [:foo], valid options are: [:name]"}
    end
  end

  describe "validate/2 - required options" do
    test "with the required option set" do
      schema = [name: [type: :string, required: true]]

      assert Validator.validate([name: "foo"], schema) == {:ok, [name: "foo"]}
    end

    test "with a missing required option" do
      schema = [name: [type: :string, required: true]]

      assert Validator.validate([], schema) == {:error, "required :name option not found"}
    end

    test "the first missing option with respect to the schema order is reported" do
      schema = [
        name: [type: :string, required: true],
        other: [type: :string, required: true]
      ]

      assert Validator.validate([], schema) == {:error, "required :name option not found"}
    end

    test "a required option with a falsy value is considered set" do
      schema = [debug: [type: :boolean, required: true]]

      assert Validator.validate([debug: false], schema) == {:ok, [debug: false]}
    end

    test "missing required options take precedence over invalid values" do
      schema = [name: [type: :string, required: true], other: [type: :string]]

      assert Validator.validate([other: 1], schema) ==
               {:error, "required :name option not found"}
    end
  end

  describe "validate/2 - default values" do
    test "defaults are applied for missing options" do
      schema = [name: [type: :string, default: "foo"]]

      assert Validator.validate([], schema) == {:ok, [name: "foo"]}
    end

    test "defaults do not override the given values" do
      schema = [name: [type: :string, default: "foo"]]

      assert Validator.validate([name: "bar"], schema) == {:ok, [name: "bar"]}
    end

    test "falsy defaults are applied" do
      schema = [debug: [type: :boolean, default: false], value: [type: :any, default: nil]]

      assert {:ok, opts} = Validator.validate([], schema)

      assert Keyword.fetch(opts, :debug) == {:ok, false}
      assert Keyword.fetch(opts, :value) == {:ok, nil}
    end

    test "options without a default are not added" do
      schema = [name: [type: :string]]

      assert Validator.validate([], schema) == {:ok, []}
    end

    test "defaults are prepended in the schema declaration order" do
      schema = [a: [type: :any, default: 1], b: [type: :any, default: 2], c: [type: :any]]

      assert Validator.validate([c: 3], schema) == {:ok, [b: 2, a: 1, c: 3]}
    end

    test "defaults are not validated against the option type" do
      schema = [name: [type: :string, default: :not_a_string]]

      assert Validator.validate([], schema) == {:ok, [name: :not_a_string]}
    end
  end

  describe "validate/2 - :any type" do
    test "accepts any value" do
      schema = [value: [type: :any]]

      for value <- [nil, 1, "foo", :foo, [1, 2], {1, 2}, %{a: 1}, false] do
        assert Validator.validate([value: value], schema) == {:ok, [value: value]}
      end
    end
  end

  describe "validate/2 - :string type" do
    test "with valid strings" do
      schema = [name: [type: :string]]

      for value <- ["", "foo", "a string with spaces"] do
        assert Validator.validate([name: value], schema) == {:ok, [name: value]}
      end
    end

    test "with invalid strings" do
      schema = [name: [type: :string]]

      for value <- [1, nil, :foo, ["foo"], true] do
        assert Validator.validate([name: value], schema) == type_error(:name, "string", value)
      end
    end
  end

  describe "validate/2 - :boolean type" do
    test "with valid booleans" do
      schema = [debug: [type: :boolean]]

      for value <- [true, false] do
        assert Validator.validate([debug: value], schema) == {:ok, [debug: value]}
      end
    end

    test "with invalid booleans" do
      schema = [debug: [type: :boolean]]

      for value <- [nil, 0, 1, "true", :true_atom] do
        assert Validator.validate([debug: value], schema) == type_error(:debug, "boolean", value)
      end
    end
  end

  describe "validate/2 - :atom type" do
    test "with valid atoms" do
      schema = [mode: [type: :atom]]

      # notice that `nil` and the booleans are atoms as well
      for value <- [:foo, nil, true, false, Foo.Bar] do
        assert Validator.validate([mode: value], schema) == {:ok, [mode: value]}
      end
    end

    test "with invalid atoms" do
      schema = [mode: [type: :atom]]

      for value <- ["foo", 1, [:foo]] do
        assert Validator.validate([mode: value], schema) == type_error(:mode, "atom", value)
      end
    end
  end

  describe "validate/2 - {:in, values} type" do
    test "with an allowed value" do
      schema = [mode: [type: {:in, [:parallel, :serial]}]]

      assert Validator.validate([mode: :parallel], schema) == {:ok, [mode: :parallel]}
    end

    test "with a value that is not allowed" do
      schema = [mode: [type: {:in, [:parallel, :serial]}]]

      assert Validator.validate([mode: :other], schema) ==
               type_error(:mode, "one of [:parallel, :serial]", :other)
    end

    test "with mixed value types" do
      schema = [mode: [type: {:in, [false, "foo", 1]}]]

      for value <- [false, "foo", 1] do
        assert Validator.validate([mode: value], schema) == {:ok, [mode: value]}
      end

      assert Validator.validate([mode: true], schema) ==
               type_error(:mode, "one of [false, \"foo\", 1]", true)
    end

    test "with no allowed values everything is invalid" do
      schema = [mode: [type: {:in, []}]]

      assert Validator.validate([mode: :foo], schema) == type_error(:mode, "one of []", :foo)
    end
  end

  describe "validate/2 - {:list, subtype} type" do
    test "with an empty list" do
      schema = [tags: [type: {:list, :string}]]

      assert Validator.validate([tags: []], schema) == {:ok, [tags: []]}
    end

    test "with valid elements" do
      schema = [tags: [type: {:list, :string}]]

      assert Validator.validate([tags: ["foo", "bar"]], schema) == {:ok, [tags: ["foo", "bar"]]}
    end

    test "with a non list value" do
      schema = [tags: [type: {:list, :string}]]

      for value <- ["foo", 1, nil, %{}] do
        assert Validator.validate([tags: value], schema) == type_error(:tags, "list", value)
      end
    end

    test "reports the position of the invalid element" do
      schema = [tags: [type: {:list, :string}]]

      assert Validator.validate([tags: [nil]], schema) ==
               {:error,
                "invalid list in :tags option: invalid value for list element at position 0: " <>
                  "expected string, got: nil"}

      assert Validator.validate([tags: ["foo", "bar", :baz]], schema) ==
               {:error,
                "invalid list in :tags option: invalid value for list element at position 2: " <>
                  "expected string, got: :baz"}
    end

    test "reports the first invalid element only" do
      schema = [tags: [type: {:list, :string}]]

      assert Validator.validate([tags: [1, 2]], schema) ==
               {:error,
                "invalid list in :tags option: invalid value for list element at position 0: " <>
                  "expected string, got: 1"}
    end

    test "a keyword list is a list of tuples" do
      schema = [tags: [type: {:list, :string}]]

      assert Validator.validate([tags: [foo: "bar"]], schema) ==
               {:error,
                "invalid list in :tags option: invalid value for list element at position 0: " <>
                  "expected string, got: {:foo, \"bar\"}"}
    end

    test "with a nested subtype" do
      schema = [modes: [type: {:list, {:in, [:a, :b]}}]]

      assert Validator.validate([modes: [:a, :b]], schema) == {:ok, [modes: [:a, :b]]}

      assert Validator.validate([modes: [:a, :c]], schema) ==
               {:error,
                "invalid list in :modes option: invalid value for list element at position 1: " <>
                  "expected one of [:a, :b], got: :c"}
    end

    test "with a list of lists" do
      schema = [matrix: [type: {:list, {:list, :string}}]]

      assert Validator.validate([matrix: [["a"], []]], schema) == {:ok, [matrix: [["a"], []]]}

      assert Validator.validate([matrix: [["a"], "b"]], schema) ==
               {:error,
                "invalid list in :matrix option: invalid value for list element at position 1: " <>
                  "expected list, got: \"b\""}
    end
  end

  describe "validate/2 - {:or, subtypes} type" do
    test "with a value matching any of the subtypes" do
      schema = [doc: [type: {:or, [:string, {:in, [false]}]}]]

      for value <- ["a doc", false] do
        assert Validator.validate([doc: value], schema) == {:ok, [doc: value]}
      end
    end

    test "with a value matching none of the subtypes" do
      schema = [doc: [type: {:or, [:string, {:in, [false]}]}]]

      assert Validator.validate([doc: 1], schema) ==
               {:error, "expected :doc option to be string or one of [false], got: 1"}
    end

    test "the subtype names are joined in the declaration order" do
      schema = [value: [type: {:or, [:boolean, :atom, :string]}]]

      assert Validator.validate([value: 1], schema) ==
               {:error, "expected :value option to be boolean or atom or string, got: 1"}
    end

    test "with a single subtype" do
      schema = [value: [type: {:or, [:string]}]]

      assert Validator.validate([value: "foo"], schema) == {:ok, [value: "foo"]}

      assert Validator.validate([value: 1], schema) ==
               {:error, "expected :value option to be string, got: 1"}
    end
  end

  describe "validate/2 - options without a type" do
    test "accept any value" do
      schema = [value: [doc: "a value with no type"]]

      for value <- [nil, 1, "foo", [1, 2]] do
        assert Validator.validate([value: value], schema) == {:ok, [value: value]}
      end
    end
  end

  describe "validate/2 - multiple options" do
    test "the first invalid value with respect to the given options order is reported" do
      schema = [name: [type: :string], debug: [type: :boolean]]

      assert Validator.validate([debug: 1, name: 2], schema) ==
               type_error(:debug, "boolean", 1)

      assert Validator.validate([name: 2, debug: 1], schema) ==
               type_error(:name, "string", 2)
    end

    test "with all options valid the defaults of the missing ones are applied" do
      schema = [
        name: [type: :string],
        debug: [type: :boolean, default: false],
        tags: [type: {:list, :string}, default: []]
      ]

      assert Validator.validate([name: "foo"], schema) ==
               {:ok, [tags: [], debug: false, name: "foo"]}
    end
  end
end
