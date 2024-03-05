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

  def validate_option_value(args, option, opts) when is_list(args) do
    values =
      Enum.reduce_while(args, [], fn arg, acc ->
        case validate_option_value(arg, option, opts) do
          {:ok, value} -> {:cont, [value | acc]}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

    case values do
      {:error, reason} -> {:error, reason}
      values -> {:ok, Enum.reverse(values)}
    end
  end

  def validate_option_value(arg, option, opts) when is_binary(arg) do
    with {:ok, value} <- validate_type(arg, option, opts[:type]) do
      {:ok, value}
    end
  end

  def validate_option_value(arg, option, opts) when is_boolean(arg) do
    {:ok, arg}
  end

  defp validate_type(arg, option, :integer) do
    case Integer.parse(arg) do
      {value, ""} -> {:ok, value}
      _other -> {:error, ":#{option} expected an integer argument, got: #{arg}"}
    end
  end

  defp validate_type(arg, option, :float) do
    case Float.parse(arg) do
      {value, ""} -> {:ok, value}
      _other -> {:error, ":#{option} expected a float argument, got: #{arg}"}
    end
  end

  defp validate_type(arg, _option, :string), do: {:ok, arg}

  def expected_args(opts) do
    case opts[:type] do
      :boolean -> 0
      :count -> 0
      _other -> 1
    end
  end
end
