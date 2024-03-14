defmodule CliOptions.SchemaTest do
  use ExUnit.Case

  describe "new!" do
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
  end
end
