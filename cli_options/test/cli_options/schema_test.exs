defmodule CliOptions.SchemaTest do
  use ExUnit.Case

  doctest CliOptions.Schema

  describe "new!" do
    test "with non keyword schema" do
      assert_raise ArgumentError, "schema was expected to be a keyword list, got: \"foo\"", fn ->
        CliOptions.Schema.new!("foo")
      end
    end

    test "with invalid schemas" do
      # invalid keys
      schema = [foo: [type: :string, missing: false, other: 1]]

      message =
        "invalid schema for :foo, unknown options [:missing, :other], valid options are: " <>
          "[:type, :default, :long, :short, :aliases, :short_aliases, :doc, :doc_section, :required, :multiple, " <>
          ":separator, :allowed, :deprecated, :env, :conflicts_with]"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid type
      schema = [foo: [type: :stringlist]]

      message =
        "invalid schema for :foo, invalid value for :type option: expected one " <>
          "of [:string, :boolean, :integer, :float, :counter, :atom], got: :stringlist"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # non string names
      schema = [foo: [long: 1]]
      message = "invalid schema for :foo, invalid value for :long option: expected string, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [short: 1]]

      message =
        "invalid schema for :foo, invalid value for :short option: expected string, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [aliases: [nil]]]

      message =
        "invalid schema for :foo, invalid list in :aliases option: invalid value for " <>
          "list element at position 0: expected string, got: nil"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [short_aliases: [:x]]]

      message =
        "invalid schema for :foo, invalid list in :short_aliases option: invalid " <>
          "value for list element at position 0: expected string, got: :x"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [aliases: 1]]

      message =
        "invalid schema for :foo, invalid value for :aliases option: expected list, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid boolean flags
      schema = [foo: [required: 1]]

      message =
        "invalid schema for :foo, invalid value for :required option: expected boolean, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [multiple: 1]]

      message =
        "invalid schema for :foo, invalid value for :multiple option: expected boolean, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid strings
      schema = [foo: [doc: 1]]
      message = ~r"invalid schema for :foo, expected :doc option"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid default values
      schema = [foo: [type: :string, default: 1]]
      message = "invalid schema for :foo, :default should be of type :string, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [type: :boolean, default: 1]]
      message = "invalid schema for :foo, :default should be of type :boolean, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [type: :integer, default: :x]]
      message = "invalid schema for :foo, :default should be of type :integer, got: :x"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [type: :counter, default: :x]]
      message = "invalid schema for :foo, :default should be of type :counter, got: :x"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [type: :atom, default: 1]]
      message = "invalid schema for :foo, :default should be of type :atom, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [type: :float, default: 1]]
      message = "invalid schema for :foo, :default should be of type :float, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # allowed values
      schema = [foo: [allowed: ["ff", 1]]]

      message =
        "invalid schema for :foo, invalid list in :allowed option: invalid value " <>
          "for list element at position 1: expected string, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid conflicts_with target
      schema = [bar: [type: :string], foo: [conflicts_with: [:bar, :baz, :project]]]

      message =
        ":foo conflicts_with must include only valid arguments, got: [:baz, :project]"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # with multiple set and default not a list
      schema = [foo: [type: :string, multiple: true, default: "foo"]]

      message =
        "invalid schema for :foo, :default should be of type {:list, :string}, got: \"foo\""

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # with multiple set and default invalid type
      schema = [foo: [type: :integer, multiple: true, default: ["foo"]]]

      message =
        "invalid schema for :foo, :default should be of type {:list, :integer}, got: [\"foo\"]"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end
    end

    test "with duplicate aliases" do
      # option name and long conflict
      schema = [foo: [type: :string], bar: [type: :string, long: "foo"]]

      assert_raise ArgumentError, "mapping foo for option :bar is already defined for :foo", fn ->
        CliOptions.Schema.new!(schema)
      end

      # long conflicts
      schema = [foo: [type: :string, long: "some"], bar: [type: :string, long: "some"]]

      assert_raise ArgumentError,
                   "mapping some for option :bar is already defined for :foo",
                   fn -> CliOptions.Schema.new!(schema) end

      # aliases conflicts
      schema = [foo: [type: :string, long: "some"], bar: [type: :string, aliases: ["some"]]]

      assert_raise ArgumentError,
                   "mapping some for option :bar is already defined for :foo",
                   fn -> CliOptions.Schema.new!(schema) end

      # short conflicts
      schema = [foo: [type: :string, short: "s"], bar: [type: :string, short_aliases: ["s"]]]

      assert_raise ArgumentError, "mapping s for option :bar is already defined for :foo", fn ->
        CliOptions.Schema.new!(schema)
      end
    end

    test "with separator set but multiple false" do
      schema = [foo: [type: :string, separator: ","]]

      message =
        "invalid schema for :foo, you are not allowed to set separator if multiple is set to false"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end
    end

    test "long short names do not interfer" do
      schema = [foo: [type: :string, long: "f"], bar: [type: :string, short_aliases: ["f"]]]
      assert %CliOptions.Schema{} = CliOptions.Schema.new!(schema)
    end

    test "default values are properly set for booleans counters" do
      # without default values set
      schema = [foo: [type: :boolean], bar: [type: :counter]]

      %CliOptions.Schema{schema: schema} = CliOptions.Schema.new!(schema)

      assert schema[:foo][:default] == false
      assert schema[:bar][:default] == 0

      # default values have precedence
      schema = [foo: [type: :boolean, default: true], bar: [type: :counter, default: 3]]

      %CliOptions.Schema{schema: schema} = CliOptions.Schema.new!(schema)

      assert schema[:foo][:default] == true
      assert schema[:bar][:default] == 3
    end

    test "default value validations" do
      schema = CliOptions.Schema.schema()

      {:in, valid_types} = schema.schema[:type][:type]

      valid_defaults = [
        string: "foo",
        integer: 1,
        boolean: false,
        float: 1.2,
        counter: 1,
        atom: :foo
      ]

      for type <- valid_types do
        # with an invalid default value
        schema = [var: [type: type, default: {1, 2}]]

        message =
          "invalid schema for :var, :default should be of type #{inspect(type)}, got: {1, 2}"

        assert_raise ArgumentError, message, fn ->
          CliOptions.Schema.new!(schema)
        end

        # with a valid default value
        schema = [var: [type: type, default: Keyword.fetch!(valid_defaults, type)]]
        assert %CliOptions.Schema{} = CliOptions.Schema.new!(schema)
      end
    end
  end
end
