defmodule CliOptions.Schema.DocsTest do
  use ExUnit.Case

  @test_schema [
    verbose: [
      type: :boolean
    ],
    project: [
      type: :string,
      alias: :p,
      required: true,
      doc: "The project to use",
      multiple: true
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

  describe "generate/2" do
    test "test schema" do
      expected =
        """
        * `--verbose` (`boolean`) -
        * `--project, -p...` (`string`) - Required. The project to use
        * `--mode` (`string`) -    Allowed values: `["parallel", "serial"]`.   [default: `parallel`]
        * `--with-dash` (`boolean`) - a key with a dash
        """
        |> String.trim()

      assert CliOptions.docs(@test_schema) == expected
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

      assert CliOptions.docs(@test_schema, sort: true) == expected
    end
  end
end
