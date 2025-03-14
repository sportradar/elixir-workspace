defmodule Workspace.CliTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  import Workspace.TestUtils

  alias Workspace.Cli

  doctest Workspace.Cli

  setup do
    Application.put_env(:elixir, :ansi_enabled, true)

    on_exit(fn -> Application.put_env(:elixir, :ansi_enabled, false) end)
  end

  test "default options sanity check" do
    default_options = Workspace.CliOptions.default_options()
    doc_sections = Workspace.CliOptions.doc_sections()

    for {option, config} <- default_options do
      assert config[:doc_section] != nil, "no doc_section defined for #{inspect(option)}"
      assert Keyword.has_key?(doc_sections, config[:doc_section])
    end
  end

  describe "options/2" do
    test "with no extra options" do
      default_options = Workspace.CliOptions.default_options()
      options = Cli.options(Keyword.keys(default_options))

      for option <- Keyword.keys(default_options) do
        assert options[option] == default_options[option]
      end
    end

    test "raises if invalid option" do
      error = assert_raise KeyError, fn -> Cli.options([:invalid]) end
      assert Exception.message(error) =~ "key [:invalid] not found in"

      error = assert_raise KeyError, fn -> Cli.options([:invalid, :foo, :bar]) end
      assert Exception.message(error) =~ "key [:bar, :foo, :invalid] not found in"
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

      assert options[:affected] == Workspace.CliOptions.option(:affected)
      refute options[:verbose] == Workspace.CliOptions.option(:verbose)
      assert options[:verbose] == extra[:verbose]
      assert options[:another_option] == extra[:another_option]
    end
  end

  describe "log/2" do
    test "with default options" do
      assert capture_io(fn ->
               Cli.log("a message")
             end) =~ "a message"
    end

    test "with prefix set" do
      assert capture_io(fn ->
               Cli.log("a message", prefix: "++> ")
             end) =~ format_ansi(["++> ", "a message"])

      assert capture_io(fn ->
               Cli.log("a message", prefix: false)
             end) =~ "a message"
    end

    test "with prefix set to :header" do
      assert capture_io(fn ->
               Cli.log("a message", prefix: :header)
             end) =~ format_ansi(["==> ", "a message"])
    end

    test "with a highlighted message" do
      assert capture_io(fn ->
               Cli.log([:project, "a message"], prefix: "--> ")
             end) =~ format_ansi(["--> ", :light_cyan, "a message"])
    end
  end

  describe "log_with_title/3" do
    test "with default options" do
      assert capture_io(fn ->
               Cli.log_with_title("section", "a message")
             end) =~ format_ansi(["section", " - ", "a message"])
    end

    test "with header prefix set" do
      assert capture_io(fn ->
               Cli.log_with_title("section", "a message", prefix: :header)
             end) =~ format_ansi(["==> ", "section", " - ", "a message"])
    end

    test "with options set" do
      assert capture_io(fn ->
               Cli.log_with_title(
                 Cli.highlight("section", :red),
                 Cli.highlight("a message", :bright),
                 prefix: "~>",
                 separator: ":"
               )
             end) =~
               format_ansi(["~>", :red, "section", :reset, ":", :bright, "a message", :reset])
    end
  end

  describe "project_name/2" do
    test "with show_status set to true" do
      opts = [show_status: true]
      project = project_fixture(app: :foo)

      # default status
      assert_ansi_lists(Cli.project_name(project, opts), [
        :light_cyan,
        ":foo",
        :reset,
        :bright,
        :green,
        " ✔",
        :reset
      ])

      # affected
      project = Workspace.Project.set_status(project, :affected)

      assert_ansi_lists(Cli.project_name(project, opts), [
        :orange,
        :bright,
        ":foo",
        :reset,
        :orange,
        :bright,
        " ●",
        :reset
      ])

      # modified
      project = Workspace.Project.set_status(project, :modified)

      assert_ansi_lists(Cli.project_name(project, opts), [
        :red,
        :bright,
        ":foo",
        :reset,
        :red,
        :bright,
        " ✚",
        :reset
      ])
    end

    test "with default options" do
      project = project_fixture(app: :foo)

      assert_ansi_lists(Cli.project_name(project, []), [:light_cyan, ":foo", :reset])
    end

    test "with a default_style set" do
      project = project_fixture(app: :foo)
      opts = [default_style: [:bright, :green]]

      assert_ansi_lists(Cli.project_name(project, opts), [:bright, :green, ":foo", :reset])
    end
  end

  test "newline/0" do
    assert capture_io(fn -> Cli.newline() end) == "\n"
  end

  defp assert_ansi_lists(output, expected) do
    assert List.flatten(output) == Cli.format(expected) |> List.flatten()
  end

  describe "debug/1" do
    test "with WORKSPACE_DEBUG disabled" do
      assert capture_io(fn ->
               Cli.debug("a debug message")
             end) == ""
    end

    test "with WORKSPACE_DEBUG enabled" do
      System.put_env("WORKSPACE_DEBUG", "true")

      assert capture_io(fn ->
               Cli.debug("a debug message")
             end) =~ format_ansi([:light_black, "a debug message"])
    after
      System.delete_env("WORKSPACE_DEBUG")
    end
  end
end
