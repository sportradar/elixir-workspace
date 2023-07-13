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
      default: "parallel"
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
  end

  describe "docs/1" do
    test "test schema" do
      expected =
        """
        * `--verbose` (`boolean`) -
        * `--project, -p...` (`string`) - Required. The project to use
        * `--mode` (`string`) -  [default: `parallel`]
        * `--with-dash` (`boolean`) - a key with a dash
        """
        |> String.trim()

      assert CliOpts.docs(@test_schema) == expected
    end
  end
end
