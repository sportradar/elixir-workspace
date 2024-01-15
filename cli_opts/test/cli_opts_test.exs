defmodule CliOptsTest do
  use ExUnit.Case
  doctest CliOpts

  @test_schema [
    verbose: [
      type: :boolean
    ],
    project: [
      type: :string,
      alias: :p,
      required: true,
      doc: "The project to use",
      keep: true
    ],
    mode: [
      type: :string,
      default: "parallel",
      allowed: ["parallel", "serial"]
    ],
    ignore: [
      type: :boolean,
      doc: false
    ],
    with_dash: [
      type: :boolean,
      doc: "a key with a dash"
    ]
  ]

  describe "parse/1" do
    test "required attributes" do
      assert {:ok, _} = CliOpts.parse(["--project", "foo"], @test_schema)
      assert {:error, _} = CliOpts.parse([], @test_schema)
    end

    test "allowed values" do
      assert {:ok, _} = CliOpts.parse(["--project", "foo", "--mode", "serial"], @test_schema)

      assert {:error, message} =
               CliOpts.parse(["--project", "foo", "--mode", "invalid"], @test_schema)

      assert message ==
               ~s'not allowed value invalid for mode, expected one of: ["parallel", "serial"]'
    end
  end

  describe "docs/1" do
    test "test schema" do
      expected =
        """
        * `--verbose` (`boolean`) -
        * `--project, -p...` (`string`) - Required. The project to use
        * `--mode` (`string`) -    Allowed values: `["parallel", "serial"]`.   [default: `parallel`]
        * `--with-dash` (`boolean`) - a key with a dash
        """
        |> String.trim()

      assert CliOpts.docs(@test_schema) == expected
    end

    test "with sorting enabled" do
      expected =
        """
        * `--mode` (`string`) -    Allowed values: `["parallel", "serial"]`.   [default: `parallel`]
        * `--project, -p...` (`string`) - Required. The project to use
        * `--verbose` (`boolean`) -
        * `--with-dash` (`boolean`) - a key with a dash
        """
        |> String.trim()

      assert CliOpts.docs(@test_schema, sort: true) == expected
    end
  end
end
