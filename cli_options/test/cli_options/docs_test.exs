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
      allowed: ["parallel", "serial"],
      doc_section: :test
    ],
    with_dash: [
      type: :boolean,
      doc: "a key with a dash",
      doc_section: :test
    ],
    hidden_option: [
      type: :boolean,
      doc: false
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

    test "with sections configured" do
      expected =
        """
        * `--verbose` (`boolean`) - [default: `false`]
        * `-p, --project...` (`string`) - Required. The project to use

        ### Test related options

        * `--mode` (`string`) - Allowed values: `["parallel", "serial"]`. [default: `parallel`]
        * `--with-dash` (`boolean`) - a key with a dash [default: `false`]
        """
        |> String.trim()

      assert CliOptions.docs(@test_schema, sections: [test: [header: "Test related options"]]) ==
               expected

      # extra sections are ignored if no option set

      assert CliOptions.docs(@test_schema,
               sections: [test: [header: "Test related options"], other: [header: "Foo"]]
             ) == expected
    end

    test "raises with invalid section settings" do
      message =
        "unknown options [:heder], valid options are: [:header, :doc] (in options [:test])"

      assert_raise NimbleOptions.ValidationError, message, fn ->
        CliOptions.docs(@test_schema, sections: [test: [heder: "Test related options"]])
      end
    end

    test "raises if no section info is provided for an option" do
      message = """
      You must include :foo in the :sections option
      of CliOptions.docs/2, as following:

          sections: [
            foo: [
              header: "The section header",
              doc: "Optional extended doc for the section"
            ]
          ]
      """

      schema = [var: [doc: "a var", long: "variable", doc_section: :foo]]

      assert_raise ArgumentError, message, fn -> CliOptions.docs(schema, sections: []) end
    end

    test "with sections configured and sorting" do
      expected =
        """
        * `-p, --project...` (`string`) - Required. The project to use
        * `--verbose` (`boolean`) - [default: `false`]

        ### Test related options

        * `--mode` (`string`) - Allowed values: `["parallel", "serial"]`. [default: `parallel`]
        * `--with-dash` (`boolean`) - a key with a dash [default: `false`]
        """
        |> String.trim()

      assert CliOptions.docs(@test_schema,
               sort: true,
               sections: [test: [header: "Test related options"]]
             ) == expected
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

    test "with env set" do
      schema = [
        var: [doc: "a var", aliases: ["var1", "var2"], short: "v", default: "foo", env: "my_env"],
        another: [doc: "another var", type: :integer, env: "ANOTHER_ENV"]
      ]

      expected =
        """
        * `-v, --var` (`string`) - a var [env: MY_ENV=] [default: `foo`] [aliases: `--var1`, `--var2`]
        * `--another` (`integer`) - another var [env: ANOTHER_ENV=]
        """
        |> String.trim()

      assert CliOptions.docs(schema) == expected
    end

    test "with separator set" do
      schema = [
        var: [doc: "a var", short: "v", multiple: true, separator: ";;"]
      ]

      expected =
        """
        * `-v, --var...` (`string`) - a var [values can be grouped with the `;;` separator]
        """
        |> String.trim()

      assert CliOptions.docs(schema) == expected
    end
  end
end
