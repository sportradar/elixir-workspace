defmodule CliOptions.Docs do
  @moduledoc false

  @doc false
  @spec generate(schema :: CliOptions.Schema.t(), opts :: keyword()) :: String.t()
  def generate(%CliOptions.Schema{schema: schema}, opts) do
    validate_sections!(schema, opts[:sections])
    sections = opts[:sections] || []

    schema
    |> remove_hidden_options()
    |> group_by_section([nil] ++ Keyword.keys(sections))
    |> maybe_sort(Keyword.get(opts, :sort, false))
    |> Enum.map(fn {section, options} -> docs_by_section(section, options, sections) end)
    |> Enum.join("\n\n")
  end

  @sections_schema NimbleOptions.new!(
                     *: [
                       type: :keyword_list,
                       keys: [
                         header: [
                           type: :string,
                           required: true
                         ],
                         doc: [type: :string]
                       ]
                     ]
                   )

  defp validate_sections!(_schema, nil), do: :ok

  defp validate_sections!(schema, sections) do
    sections = NimbleOptions.validate!(sections, @sections_schema)

    configured_sections =
      schema
      |> Enum.map(fn {_key, opts} -> opts[:doc_section] end)
      |> Enum.reject(&is_nil/1)

    for section <- configured_sections do
      if is_nil(sections[section]) do
        raise ArgumentError, """
        You must include #{inspect(section)} in the :sections option
        of CliOptions.docs/2, as following:

            sections: [
              #{section}: [
                header: "The section header",
                doc: "Optional extended doc for the section"
              ]
            ]
        """
      end
    end
  end

  defp remove_hidden_options(schema),
    do: Enum.reject(schema, fn {_key, opts} -> opts[:doc] == false end)

  defp group_by_section(schema, [nil]), do: [nil: schema]

  defp group_by_section(schema, sections) do
    sections
    |> Enum.reduce([], fn section, acc ->
      options = Enum.filter(schema, fn {_key, opts} -> opts[:doc_section] == section end)

      case options do
        [] -> acc
        options -> [{section, options} | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp maybe_sort(sections, true) do
    Enum.map(sections, fn {section, options} ->
      sorted = Enum.sort_by(options, fn {key, _value} -> key end, :asc)
      {section, sorted}
    end)
  end

  defp maybe_sort(sections, _other), do: sections

  defp docs_by_section(nil, options, _sections), do: options_docs(options)

  defp docs_by_section(section, options, sections) do
    section_opts = Keyword.fetch!(sections, section)

    [
      "### " <> Keyword.fetch!(section_opts, :header),
      section_opts[:doc],
      options_docs(options)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp options_docs(options) do
    options
    |> Enum.map(fn {_key, schema} -> option_doc(schema) end)
    |> Enum.join("\n")
  end

  defp option_doc(schema) do
    [
      "*",
      "`#{option_name_doc(schema)}`",
      "(`#{schema[:type]}`)",
      "-",
      maybe_deprecated(schema),
      maybe_required(schema),
      option_body_doc(schema)
    ]
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.join(" ")
    |> String.trim_trailing()
  end

  defp option_name_doc(schema) do
    [
      format_short(schema),
      format_long(schema)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.join(", ")
    |> maybe_repeating(schema)
  end

  defp format_long(schema), do: "--#{Keyword.fetch!(schema, :long)}"

  defp format_short(schema) do
    case schema[:short] do
      nil -> nil
      alias -> "-#{alias}"
    end
  end

  defp maybe_deprecated(schema) do
    case schema[:deprecated] do
      nil -> nil
      message -> "*DEPRECATED #{message}*"
    end
  end

  defp maybe_required(schema) do
    case schema[:required] do
      true -> "Required. "
      _ -> nil
    end
  end

  defp maybe_repeating(key, schema) do
    case schema[:multiple] do
      true -> "#{key}..."
      _ -> key
    end
  end

  defp option_body_doc(schema) do
    [
      schema[:doc],
      maybe_allowed(schema),
      maybe_env(schema),
      maybe_default(schema),
      maybe_aliases(schema)
    ]
    |> Enum.reject(fn part -> is_nil(part) or part == "" end)
    |> Enum.join(" ")
  end

  defp maybe_allowed(schema) do
    case schema[:allowed] do
      nil -> ""
      allowed -> "Allowed values: `#{inspect(allowed)}`."
    end
  end

  defp maybe_env(schema) do
    case schema[:env] do
      nil ->
        nil

      env ->
        env = String.upcase(env)
        "[env: #{env}=]"
    end
  end

  defp maybe_default(schema) do
    case schema[:default] do
      nil -> ""
      default -> "[default: `#{default}`]"
    end
  end

  defp maybe_aliases(schema) do
    aliases = Enum.map(schema[:aliases], fn a -> "`--#{a}`" end)
    short_aliases = Enum.map(schema[:short_aliases], fn a -> "`-#{a}`" end)

    case aliases ++ short_aliases do
      [] ->
        nil

      aliases ->
        aliases_string = Enum.join(aliases, ", ")

        "[aliases: #{aliases_string}]"
    end
  end
end
