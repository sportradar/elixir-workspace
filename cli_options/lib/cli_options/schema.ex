defmodule CliOptions.Schema do
  @moduledoc """
  The schema for command line options.

  TODO: extend moduledoc
  """

  @type t :: %__MODULE__{
          schema: keyword(),
          mappings: %{String.t() => atom()}
        }

  @enforce_keys [:schema, :mappings]
  defstruct schema: [], mappings: []

  def validate(schema) do
    # TODO: proper schema validation

    mappings = build_mappings(schema)

    {:ok, %__MODULE__{schema: schema, mappings: mappings}}
  end

  def ensure_valid_option(option, schema) do
    case Map.get(schema.mappings, option) do
      nil -> {:error, "invalid option #{inspect(option)}"}
      option -> {:ok, option, schema.schema[option]}
    end
  end

  defp build_mappings(schema) do
    for {option, opts} <- schema, mapping <- option_mappings(option, opts), into: %{} do
      {mapping, option}
    end
  end

  defp option_mappings(option, opts) do
    [
      long_name(opts, option),
      opts[:short]
    ]
    |> Enum.concat(opts[:aliases] || [])
    |> Enum.concat(opts[:short_aliases] || [])
    |> Enum.reject(&is_nil/1)
  end

  defp long_name(opts, option) do
    case opts[:long] do
      nil ->
        Atom.to_string(option) |> String.replace("_", "-")

      long ->
        long
    end
  end
end
