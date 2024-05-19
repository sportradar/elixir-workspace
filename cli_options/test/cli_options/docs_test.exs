defmodule CliOptions.DocsTest do
  use ExUnit.Case

  @test_schema [
    verbose: [
      type: :boolean
    ],
    project: [
      type: :string,
      short: "p",
      required: true,
      doc: "The project to use",
      multiple: true
    ],
    mode: [
      type: :string,
      default: "parallel",
      allowed: ["parallel", "serial"]
    ],
    with_dash: [
      type: :boolean,
      doc: "a key with a dash"
    ],
    hidden_option: [
      type: :boolean,
      hidden: true
    ]
  ]

  describe "generate/2" do
    test "test schema" do
      expected =
        """
        * `--verbose` (`boolean`) - [default: `false`]
        * `-p, --project...` (`string`) - Required. The project to use
        * `--mode` (`string`) - Allowed values: `["parallel", "serial"]`. [default: `parallel`]
        * `--with-dash` (`boolean`) - a key with a dash [default: `false`]
        """
        |> String.trim()

      assert CliOptions.docs(@test_schema) == expected
    end

    test "with sorting enabled" do
      expected =
        """
        * `--mode` (`string`) - Allowed values: `["parallel", "serial"]`. [default: `parallel`]
        * `-p, --project...` (`string`) - Required. The project to use
        * `--verbose` (`boolean`) - [default: `false`]
        * `--with-dash` (`boolean`) - a key with a dash [default: `false`]
        """
        |> String.trim()

      assert CliOptions.docs(@test_schema, sort: true) == expected
    end

    test "prints deprecation info" do
      schema = [
        old: [type: :string, doc: "old option", deprecated: "use --new"],
        new: [type: :string, doc: "new option"]
      ]

      expected =
        """
        * `--old` (`string`) - *DEPRECATED use --new* old option
        * `--new` (`string`) - new option
        """
        |> String.trim()

      assert CliOptions.docs(schema) == expected
    end

    test "custom long name is used" do
      schema = [var: [doc: "a var", long: "variable"]]

      expected =
        """
        * `--variable` (`string`) - a var
        """
        |> String.trim()

      assert CliOptions.docs(schema) == expected
    end

    test "aliases are included in doc" do
      schema = [
        var: [doc: "a var", aliases: ["var1", "var2"], short: "v", short_aliases: ["V", "u"]]
      ]

      expected =
        """
        * `-v, --var` (`string`) - a var [aliases: `--var1`, `--var2`, `-V`, `-u`]
        """
        |> String.trim()

      assert CliOptions.docs(schema) == expected
    end
  end
end
