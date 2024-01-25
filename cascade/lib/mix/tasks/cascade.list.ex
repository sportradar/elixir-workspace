defmodule Mix.Tasks.Cascade.List do
  @shortdoc "Lists available templates"

  @moduledoc """
  
  """
  use Mix.Task
  
  @impl Mix.Task
  def run(argv) do
    case argv do
      [] -> 
        Mix.shell().info("The following templates are available:")
        Mix.shell().info("")
        list_templates()
        Mix.shell().info("")
        Mix.shell().info(["Run ", :yellow, "mix cascade NAME", :reset, " to generate a template"])
        Mix.shell().info(["Run ", :yellow, "mix cascade.help NAME", :reset, " to see help of a specific template"])

      _other ->
        Mix.raise("Unexpected arguments, expected \"mix cascade.list\"")
    end
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
    |> Enum.map(fn {name, doc} -> ["  ", :bright, :cyan, String.pad_trailing(name, max), :reset, "  # ", doc] end)
    |> Enum.each(fn line -> Mix.shell().info(line) end)
  end

  defp shortdoc(module) do
    case Cascade.Template.shortdoc(module) do
      nil -> ""
      shortdoc -> shortdoc
    end
  end
end
