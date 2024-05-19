defmodule CliOptions.Docs do
  @moduledoc false

  @doc false
  @spec generate(schema :: CliOptions.Schema.t(), opts :: keyword()) :: String.t()
  def generate(%CliOptions.Schema{} = schema, opts) do
    schema.schema
    |> remove_hidden_options()
    |> maybe_sort(Keyword.get(opts, :sort, false))
    |> Enum.reduce([], &maybe_option_doc/2)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp remove_hidden_options(schema),
    do: Enum.reject(schema, fn {_key, opts} -> opts[:hidden] end)

  defp maybe_sort(schema, true), do: Enum.sort_by(schema, fn {key, _value} -> key end, :asc)
  defp maybe_sort(schema, _other), do: schema

  defp maybe_option_doc({key, schema}, acc) do
    option_doc({key, schema}, acc)
  end

  defp option_doc({key, schema}, acc) do
    doc =
      [
        "*",
        "`#{key_doc(key, schema)}`",
        "(`#{schema[:type]}`)",
        "-",
        maybe_deprecated(schema),
        maybe_required(schema),
        key_body_doc(schema)
      ]
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&String.trim_trailing/1)
      |> Enum.join(" ")
      |> String.trim_trailing()

    [doc | acc]
  end

  defp key_doc(key, schema) do
    "--#{format_key(key)}#{maybe_alias(schema)}"
    |> maybe_repeating(schema)
  end

  defp format_key(key), do: String.replace("#{key}", "_", "-")

  defp maybe_alias(schema) do
    case schema[:short] do
      nil -> ""
      alias -> ", -#{alias}"
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

  defp key_body_doc(schema) do
    [
      schema[:doc],
      maybe_allowed(schema),
      maybe_default(schema)
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

  defp maybe_default(schema) do
    case schema[:default] do
      nil -> ""
      default -> "[default: `#{default}`]"
    end
  end
end
