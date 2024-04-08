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

    schema = validate_options!(schema)

    mappings = build_mappings(schema)

    %__MODULE__{schema: schema, mappings: mappings}
  end

  # we are manually validating the schema for now, could be delegated to NimbleOptions
  # but we want to avoid external dependencies. If it goes out of hand we may consider
  # refactoring it accordingly
  defp validate_options!(schema) do
    for {option, opts} <- schema do
      validate_option!(option, opts)
    end
  end

  defp validate_option!(option, opts) do
    with :ok <- validate_keys(Keyword.keys(opts)),
         {:ok, opts} <- validate_type(opts),
         {:ok, opts} <- validate_names(option, opts),
         :ok <- ensure_boolean_or_nil(opts[:required], :required),
         :ok <- ensure_boolean_or_nil(opts[:multiple], :multiple),
         :ok <- ensure_binary_or_nil(opts[:doc], :doc),
         {:ok, opts} <- validate_default_value(opts) do
      {option, opts}
    else
      {:error, reason} -> raise ArgumentError, "invalid schema for :#{option}, #{reason}"
    end
  end

  @valid_option_keys [
    :type,
    :long,
    :short,
    :doc,
    :default,
    :required,
    :multiple,
    :aliases,
    :short_aliases
  ]
  defp validate_keys(keys) do
    invalid_keys = keys -- @valid_option_keys

    case invalid_keys do
      [] -> :ok
      invalid -> {:error, "the following schema keys are not supported: #{inspect(invalid)}"}
    end
  end

  @valid_types [:string, :boolean, :integer, :float, :counter, :atom]

  defp validate_type(opts) do
    opts = Keyword.put_new(opts, :type, :string)
    type = Keyword.fetch!(opts, :type)

    case type in @valid_types do
      true -> {:ok, opts}
      false -> {:error, "invalid type #{inspect(type)}"}
    end
  end

  defp validate_names(option, opts) do
    opts =
      opts
      |> Keyword.put_new(:long, default_long_name(option))
      |> Keyword.put_new(:aliases, [])
      |> Keyword.put_new(:short_aliases, [])

    with :ok <- ensure_binary(opts[:long], :long),
         :ok <- ensure_binary_or_nil(opts[:short], :short),
         :ok <- ensure_binary_list(opts[:aliases], :aliases),
         :ok <- ensure_binary_list(opts[:short_aliases], :short_aliases) do
      {:ok, opts}
    end
  end

  defp default_long_name(option), do: Atom.to_string(option) |> String.replace("_", "-")

  defp ensure_binary_or_nil(nil, _name), do: :ok
  defp ensure_binary_or_nil(value, name), do: ensure_binary(value, name)

  defp ensure_binary(value, _name) when is_binary(value), do: :ok

  defp ensure_binary(value, name),
    do: {:error, "#{inspect(name)} should be a string, got: #{inspect(value)}"}

  defp ensure_binary_list([], _name), do: :ok

  defp ensure_binary_list([head | rest], name) do
    case ensure_binary(head, name) do
      :ok ->
        ensure_binary_list(rest, name)

      _error ->
        {:error,
         "#{inspect(name)} expected a list of strings, got a non string item: #{inspect(head)}"}
    end
  end

  defp ensure_binary_list(value, name),
    do: {:error, "#{inspect(name)} expected a list of strings, got: #{inspect(value)}"}

  defp ensure_boolean_or_nil(nil, _name), do: :ok
  defp ensure_boolean_or_nil(value, _name) when is_boolean(value), do: :ok

  defp ensure_boolean_or_nil(value, name),
    do: {:error, "#{inspect(name)} should be boolean, got: #{inspect(value)}"}

  defp validate_default_value(opts) do
    opts = maybe_add_default_value(opts, opts[:type])

    case validate_type_match(opts[:type], opts[:default]) do
      true ->
        {:ok, opts}

      false ->
        {:error,
         ":default should be of type #{inspect(opts[:type])}, got: #{inspect(opts[:default])}"}
    end
  end

  defp maybe_add_default_value(opts, :boolean), do: Keyword.put_new(opts, :default, false)
  defp maybe_add_default_value(opts, :counter), do: Keyword.put_new(opts, :default, 0)
  defp maybe_add_default_value(opts, _other), do: opts

  defp validate_type_match(_type, nil), do: true

  defp validate_type_match(:integer, value), do: is_integer(value)
  defp validate_type_match(:counter, value), do: is_integer(value)
  defp validate_type_match(:string, value), do: is_binary(value)
  defp validate_type_match(:float, value), do: is_float(value)
  defp validate_type_match(:atom, value), do: is_atom(value)
  defp validate_type_match(:boolean, value), do: is_boolean(value)

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
        :set_true

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
