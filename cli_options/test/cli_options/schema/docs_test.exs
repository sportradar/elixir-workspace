defmodule CliOptions.Schema.DocsTest do
  use ExUnit.Case

  alias CliOptions.Schema.Docs

  describe "generate/1" do
    test "with the option types" do
      schema = [
        name: [type: :string, doc: "a string"],
        debug: [type: :boolean, doc: "a boolean"],
        mode: [type: :atom, doc: "an atom"],
        value: [type: :any, doc: "anything"],
        tags: [type: {:list, :string}, doc: "a list of strings"]
      ]

      expected =
        """
        * `:name` (`t:String.t/0`) - a string

        * `:debug` (`t:boolean/0`) - a boolean

        * `:mode` (`t:atom/0`) - an atom

        * `:value` (`t:term/0`) - anything

        * `:tags` (list of `t:String.t/0`) - a list of strings
        """
        |> String.trim()

      assert Docs.generate(schema) == expected
    end

    test "types that are not concisely expressible are not documented" do
      schema = [
        mode: [type: {:in, [:parallel, :serial]}, doc: "the mode"],
        doc: [type: {:or, [:string, {:in, [false]}]}, doc: "the docs"]
      ]

      expected =
        """
        * `:mode` - the mode

        * `:doc` - the docs
        """
        |> String.trim()

      assert Docs.generate(schema) == expected
    end

    test "with an explicit type_doc" do
      schema = [
        doc: [
          type: {:or, [:string, {:in, [false]}]},
          type_doc: "`t:String.t/0` or `false`",
          doc: "the docs"
        ]
      ]

      assert Docs.generate(schema) == "* `:doc` (`t:String.t/0` or `false`) - the docs"
    end

    test "with default values" do
      schema = [
        name: [type: :string, doc: "a string", default: "foo"],
        tags: [type: {:list, :string}, doc: "a list", default: []]
      ]

      expected =
        """
        * `:name` (`t:String.t/0`) - a string The default value is `"foo"`.

        * `:tags` (list of `t:String.t/0`) - a list The default value is `[]`.
        """
        |> String.trim()

      assert Docs.generate(schema) == expected
    end

    test "with multiline docs the default is added in a trailing paragraph" do
      schema = [
        name: [
          type: :string,
          doc: """
          a string

              an indented code block
          """,
          default: "foo"
        ]
      ]

      expected =
        """
        * `:name` (`t:String.t/0`) - a string

              an indented code block

          The default value is `"foo"`.
        """
        |> String.trim_trailing()

      assert Docs.generate(schema) == expected
    end
  end
end
