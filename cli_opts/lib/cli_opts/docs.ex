defmodule CliOpts.Docs do
  @moduledoc false

  @doc false
  @spec generate(schema :: keyword()) :: String.t()
  def generate(schema) do
    schema
    |> Enum.reduce([], &maybe_option_doc/2)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  defp maybe_option_doc({key, schema}, acc) do
    if schema[:doc] == false do
      acc
    else
      option_doc({key, schema}, acc)
    end
  end

  defp option_doc({key, schema}, acc) do
    doc =
      """
      * `#{key_doc(key, schema)}` (`#{schema[:type]}`) - #{maybe_required(schema)}#{key_body_doc(schema)}
      """
      |> String.trim_trailing()

    [doc | acc]
  end

  defp key_doc(key, schema) do
    "--#{format_key(key)}#{maybe_alias(schema)}"
    |> maybe_repeating(schema)
  end

  defp format_key(key), do: String.replace("#{key}", "_", "-")

  defp maybe_alias(schema) do
    case schema[:alias] do
      nil -> ""
      alias -> ", -#{alias}"
    end
  end

  defp maybe_required(schema) do
    case schema[:required] do
      true -> "Required. "
      _ -> ""
    end
  end

  defp maybe_repeating(key, schema) do
    case schema[:keep] do
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
    |> Enum.join("")
  end

  defp maybe_allowed(schema) do
    case schema[:allowed] do
      nil -> ""
      allowed -> "   Allowed values: `#{inspect(allowed)}`."
    end
  end

  defp maybe_default(schema) do
    case schema[:default] do
      nil -> ""
      default -> "   [default: `#{default}`]"
    end
  end
end