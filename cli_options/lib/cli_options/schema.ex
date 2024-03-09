defmodule CliOptions.Schema do
  @moduledoc """
  The schema for command line options.

  TODO: extend moduledoc
  """

  @type t :: %__MODULE__{
          schema: keyword(),
          mappings: %{String.t() => atom()}
        }

  defstruct schema: [], mappings: []

  # validates the schema, rename to new! similar to nimbleoptiosn
  def validate(schema) do
    # TODO: proper schema validation

    mappings = build_mappings(schema)

    {:ok, %__MODULE__{schema: schema, mappings: mappings}}
  end

  # opts is expected to be a keyword of the form [option: args]
  # where args a list of the specified args for this option or a single arg
  def validate(opts, schema) do
    # TODO: custom validation
    result =
      Enum.reduce_while(schema.schema, [], fn {option, option_schema}, acc ->
        case validate_option(option, opts[option], option_schema) do
          {:ok, value} -> {:cont, [{option, value} | acc]}
          :no_value -> {:cont, acc}
          {:error, _reason} = error -> {:halt, error}
        end
      end)

    case result do
      {:error, reason} -> {:error, reason}
      options -> {:ok, Enum.reverse(options)}
    end
  end

  defp validate_option(option, value, schema) do
    value = value || schema[:default]

    with {:ok, value} <- validate_value(option, value, schema),
         {:ok, value} <- validate_type(option_type(schema), option, value) do
      {:ok, value}
    end
  end

  defp validate_value(option, value, schema) do
    cond do
      value != nil ->
        {:ok, value}

      Keyword.get(schema, :required, false) ->
        {:error, "option :#{option} is required"}

      true ->
        :no_value
    end
  end

  defp option_type(schema) do
    case schema[:multiple] do
      true -> {:list, schema[:type]}
      _other -> schema[:type]
    end
  end

  defp validate_type({:list, type}, option, values) when is_list(values) do
    result =
      Enum.reduce_while(values, [], fn value, acc ->
        case validate_type(type, option, value) do
          {:ok, value} -> {:cont, [value | acc]}
          error -> {:halt, error}
        end
      end)

    case result do
      {:error, reason} -> {:error, reason}
      values -> {:ok, Enum.reverse(values)}
    end
  end

  defp validate_type(:integer, _option, value) when is_integer(value), do: {:ok, value}

  defp validate_type(:integer, option, value) when is_binary(value) do
    case Integer.parse(value) do
      {value, ""} -> {:ok, value}
      _other -> {:error, ":#{option} expected an integer argument, got: #{value}"}
    end
  end

  defp validate_type(:float, option, value) when is_binary(value) do
    case Float.parse(value) do
      {value, ""} -> {:ok, value}
      _other -> {:error, ":#{option} expected a float argument, got: #{value}"}
    end
  end

  defp validate_type(:string, _option, value) when is_binary(value), do: {:ok, value}
  defp validate_type(:boolean, _option, value) when is_boolean(value), do: {:ok, value}

  def action(option, schema) do
    opts = Keyword.fetch!(schema, option)

    type = opts[:type]
    action = opts[:action]

    cond do
      action != nil ->
        action

      type == :boolean ->
        :set_true

      opts[:multiple] ->
        :append

      true ->
        :set
    end
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

  def expected_args(opts) do
    case opts[:type] do
      :boolean -> 0
      :count -> 0
      _other -> 1
    end
  end
end
