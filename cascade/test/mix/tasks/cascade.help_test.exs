defmodule Mix.Tasks.Cascade.HelpTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  defmodule TemplateNoDocs do
    use Cascade.Template

    @impl true
    def name, do: :no_docs

    @impl true
    def assets_path, do: Path.expand("invalid_path", __DIR__)
  end

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  test "lists all templates" do
    captured =
      capture_io(fn ->
        Mix.Tasks.Cascade.Help.run([])
      end)

    assert captured =~ "template_no_docs  #"
    assert captured =~ "template          # Generates a new template"
    assert captured =~ "no_docs           #"
    assert captured =~ "Run mix cascade NAME to generate a template"
    assert captured =~ "Run mix cascade.help NAME to see help of a specific template"
  end

  test "cascade.help TEMPLATE" do
    captured =
      capture_io(fn ->
        Mix.Tasks.Cascade.Help.run(["template"])
      end)

    assert captured =~ "mix cascade template"
    assert captured =~ "## Command line options"
  end

  test "with a template without docs" do
    captured =
      capture_io(fn ->
        Mix.Tasks.Cascade.Help.run(["no_docs"])
      end)

    assert String.trim(captured) == "mix cascade no_docs"
  end

  test "with invalid template" do
    message =
      "No template `invalid` found. Run \"mix cascade.help\" to get a list of available templates"

    assert_raise Mix.Error, message, fn ->
      Mix.Tasks.Cascade.Help.run(["invalid"])
    end
  end

  test "with invalid arguments" do
    message =
      "Unexpected arguments, expected \"mix cascade.help\" or \"mix cascade.help TEMPLATE\""

    assert_raise Mix.Error, message, fn ->
      Mix.Tasks.Cascade.Help.run(["--invalidff"])
    end

    assert_raise Mix.Error, message, fn ->
      Mix.Tasks.Cascade.Help.run(["foo", "bar"])
    end
  end
end
