defmodule Mix.Tasks.Cascade.Help do
  @shortdoc "Lists available templates or prints the documentation for a given template"

  @moduledoc """
  Lists available templates or prints the documentation for a given template.

  ## Usage

      $ mix cascade.help          - prints all available templates and their short description
      $ mix cascade.help TEMPLATE - prints full docs for the given template
  """
  use Mix.Task

  @impl Mix.Task
  def run([]) do
    Mix.shell().info("The following templates are available:")
    Mix.shell().info("")
    list_templates()
    Mix.shell().info("")
    Mix.shell().info(["Run ", :yellow, "mix cascade NAME", :reset, " to generate a template"])

    Mix.shell().info([
      "Run ",
      :yellow,
      "mix cascade.help NAME",
      :reset,
      " to see help of a specific template"
    ])
  end

  def run([template]) do
    templates = Cascade.templates()

    case templates[String.to_atom(template)] do
      nil ->
        Mix.raise(
          "No tempalte `#{template}` found. Run \"mix cascade.help\" to get a list of available templates"
        )

      module ->
        docs = Cascade.Template.moduledoc(module)
        opts = [width: width(), enabled: true]

        IO.ANSI.Docs.print_headings(["mix cascade #{template}"], opts)
        IO.ANSI.Docs.print(docs, "text/markdown", opts)
    end
  end

  def run(_other) do
    Mix.raise("Unexpected arguments, expected \"mix cascade.list\"")
  end

  defp list_templates do
    templates =
      Cascade.templates()
      |> Enum.sort_by(fn {name, _module} -> name end)
      |> Enum.map(fn {name, module} -> {Atom.to_string(name), shortdoc(module)} end)

    max =
      templates
      |> Enum.map(fn {name, _doc} -> byte_size(name) end)
      |> Enum.max()

    templates
    |> Enum.map(fn {name, doc} ->
      ["  ", :bright, :cyan, String.pad_trailing(name, max), :reset, "  # ", doc]
    end)
    |> Enum.each(fn line -> Mix.shell().info(line) end)
  end

  defp shortdoc(module) do
    case Cascade.Template.shortdoc(module) do
      nil -> ""
      shortdoc -> shortdoc
    end
  end

  defp width() do
    case :io.columns() do
      {:ok, width} -> min(width, 80)
      {:error, _} -> 80
    end
  end
end
