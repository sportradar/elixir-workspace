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
        "invalid schema for :foo, the following schema keys are not supported: [:missing, :other]"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid type
      schema = [foo: [type: :stringlist]]
      message = "invalid schema for :foo, invalid type :stringlist"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # non string names
      schema = [foo: [long: 1]]
      message = "invalid schema for :foo, :long should be a string, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [short: 1]]
      message = "invalid schema for :foo, :short should be a string, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [aliases: [nil]]]

      message =
        "invalid schema for :foo, :aliases expected a list of strings, got a non string item: nil"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [short_aliases: [:x]]]

      message =
        "invalid schema for :foo, :short_aliases expected a list of strings, got a non string item: :x"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [aliases: 1]]
      message = "invalid schema for :foo, :aliases expected a list of strings, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid boolean flags
      schema = [foo: [required: 1]]
      message = "invalid schema for :foo, :required should be boolean, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      schema = [foo: [multiple: 1]]
      message = "invalid schema for :foo, :multiple should be boolean, got: 1"

      assert_raise ArgumentError, message, fn ->
        CliOptions.Schema.new!(schema)
      end

      # invalid strings
      schema = [foo: [doc: 1]]
      message = "invalid schema for :foo, :doc should be a string, got: 1"

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
        "invalid schema for :foo, :allowed expected a list of strings, got a non string item: 1"

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

      # long short do not interfere
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
  end
end
