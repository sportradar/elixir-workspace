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
  def new!(schema) do
    if not Keyword.keyword?(schema) do
      raise ArgumentError, "schema was expected to be a keyword list, got: #{inspect(schema)}"
    end

    schema = CliOptions.Schema.Validation.validate!(schema)
    mappings = build_mappings(schema)

    %__MODULE__{schema: schema, mappings: mappings}
  end

  defp build_mappings(schema) do
    mappings = %{}

    for {option, opts} <- schema, mapping <- option_mappings(opts), reduce: mappings do
      mappings when is_map_key(mappings, mapping) ->
        raise ArgumentError,
              "mapping #{mapping} for option :#{option} is already defined for :#{mappings[mapping]}"

      mappings ->
        Map.put(mappings, mapping, option)
    end
  end

  defp option_mappings(opts) do
    [
      opts[:long],
      opts[:short]
    ]
    |> Enum.concat(opts[:aliases])
    |> Enum.concat(opts[:short_aliases])
    |> Enum.reject(&is_nil/1)
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
    value = value_or_default(value, schema)

    with {:ok, value} <- validate_value(option, value, schema),
         {:ok, value} <- validate_type(option_type(schema), option, value) do
      {:ok, value}
    end
  end

  defp value_or_default(value, _schema) when not is_nil(value), do: value
  defp value_or_default(nil, schema), do: schema[:default]

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

  @integer_types [:integer, :counter]
  defp validate_type(integer_type, _option, value)
       when integer_type in @integer_types and is_integer(value),
       do: {:ok, value}

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

  defp validate_type(:atom, _option, value) when is_binary(value),
    do: {:ok, String.to_atom(value)}

  defp validate_type(:boolean, _option, value) when is_boolean(value), do: {:ok, value}

  def action(option, schema) do
    opts = Keyword.fetch!(schema, option)

    type = opts[:type]

    cond do
      type == :boolean ->
        :negate

      type == :counter ->
        :count

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

  def expected_args(opts) do
    cond do
      opts[:type] == :boolean -> 0
      opts[:type] == :counter -> 0
      true -> 1
    end
  end
end
