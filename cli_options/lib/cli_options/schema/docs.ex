defmodule CliOptions.Schema.Docs do
  @moduledoc false

  # Generates the markdown documentation of a validation schema. It is used for
  # documenting the supported settings of a `CliOptions` schema.

  @doc """
  Generates a markdown list documenting the given validation `schema`.

  Each option is rendered as a list item including its type, documentation and
  default value, if set.
  """
  @spec generate(schema :: keyword()) :: String.t()
  def generate(schema), do: Enum.map_join(schema, "\n\n", &option_doc/1)

  defp option_doc({key, settings}) do
    body =
      settings[:doc]
      |> String.trim()
      |> maybe_add_default(settings)
      |> indent()

    "* `#{inspect(key)}`#{type_doc(settings)} - #{body}"
  end

  # if the docs span multiple paragraphs the default value is added in a
  # trailing paragraph, in order to avoid hiding it in the middle of the text
  defp maybe_add_default(doc, settings) do
    case Keyword.has_key?(settings, :default) do
      false ->
        doc

      true ->
        default = "The default value is `#{inspect(settings[:default])}`."

        case String.contains?(doc, "\n\n") do
          true -> doc <> "\n\n" <> default
          false -> doc <> " " <> default
        end
    end
  end

  defp indent(doc) do
    [first | rest] = String.split(doc, "\n")

    Enum.join([first | Enum.map(rest, &indent_line/1)], "\n")
  end

  defp indent_line(""), do: ""
  defp indent_line(line), do: "  " <> line

  defp type_doc(settings) do
    case Keyword.fetch(settings, :type_doc) do
      {:ok, type_doc} -> " (#{type_doc})"
      :error -> raw_type_doc(settings[:type])
    end
  end

  defp raw_type_doc(type) do
    case type_name(type) do
      nil -> ""
      name -> " (#{name})"
    end
  end

  # types that are not concisely expressible are not documented, their
  # description is expected to be part of the option's `:doc`
  defp type_name(:any), do: "`t:term/0`"
  defp type_name(:string), do: "`t:String.t/0`"
  defp type_name(:boolean), do: "`t:boolean/0`"
  defp type_name(:atom), do: "`t:atom/0`"
  defp type_name({:list, subtype}), do: "list of #{type_name(subtype)}"
  defp type_name({:in, _values}), do: nil
  defp type_name({:or, _subtypes}), do: nil
end
