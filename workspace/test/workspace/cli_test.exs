defmodule Workspace.CliTest do
  use ExUnit.Case
  alias Workspace.Cli

  @valid_options [
    :affected,
    :ignore,
    :task,
    :execution_order,
    :execution_mode,
    :verbose,
    :workspace_path,
    :config_path
  ]

  describe "options/2" do
    test "with no extra options" do
      options = Cli.options(@valid_options)

      for option <- @valid_options do
        assert options[option] == Workspace.Cli.Options.option(option)
      end
    end

    test "raises if invalid option" do
      assert_raise ArgumentError, "invalid option :invalid", fn -> Cli.options([:invalid]) end
    end

    test "merges with extras and overrides" do
      extra = [
        verbose: [
          type: :string,
          doc: "another verbose"
        ],
        another_option: [
          type: :boolean,
          default: false,
          doc: "another option"
        ]
      ]

      options = Cli.options([:verbose, :affected], extra)

      assert options[:affected] == Cli.Options.option(:affected)
      refute options[:verbose] == Cli.Options.option(:verbose)
      assert options[:verbose] == extra[:verbose]
      assert options[:another_option] == extra[:another_option]
    end
  end
end
