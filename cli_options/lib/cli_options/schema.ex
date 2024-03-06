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

  # validates the schema, rename to new! similar to nimbleoptiosn
  def validate(schema) do
    # TODO: proper schema validation

    mappings = build_mappings(schema)

    {:ok, %__MODULE__{schema: schema, mappings: mappings}}
  end

  def validate(opts, schema) do
    defaults =
      Enum.map(schema.schema, fn {key, key_opts} -> {key, key_opts[:default]} end)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    # TODO: custom validation
    # merging of multiple keys
    # required validation
    opts = Keyword.merge(defaults, opts)

    with {:ok, opts} <- validate_options(opts, schema),
         {:ok, opts} <- validate_required(opts, schema) do
      {:ok, opts}
    end
  end

  defp validate_required(opts, schema) do
    {:ok, opts}
  end

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

  defp validate_options(opts, schema) do
    options =
      Enum.reduce_while(opts, [], fn {option, value}, acc ->
        option_schema = Keyword.fetch!(schema.schema, option)

        case validate_option_value(value, option, option_schema) do
          {:ok, value} -> {:cont, [{option, value} | acc]}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

    case options do
      {:error, reason} -> {:error, reason}
      opts -> {:ok, Enum.reverse(opts)}
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

  # TODO: instead of this use a maybe_cast and a validate function
  def validate_option_value(arg, option, opts), do: {:ok, arg}

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
