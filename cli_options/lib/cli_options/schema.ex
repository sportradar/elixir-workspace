defmodule CliOptions.Schema do
  @moduledoc """
  The schema for command line options.

  ## Schema Options

  The following are the options supported in a schema. They are used for validating
  passed command line arguments:

    * `:type` (`t:atom/0`) - The type of the argument. Can be one of
    #{inspect(CliOptions.Schema.Validation.valid_types())}. If not set defaults to `:string`.

      ```cli
      schema = [
        name: [type: :string],
        retries: [type: :integer],
        interval: [type: :float],
        debug: [type: :boolean],
        verbose: [type: :counter],
        mode: [type: :atom]
      ]

      CliOptions.parse!(
        ["--name", "foo", "--retries", "3", "--interval", "2.5", "--debug"],
        schema
      )
      >>>

      CliOptions.parse!(
        ["--verbose", "--verbose", "--mode", "parallel"],
        schema
      )
      ```

    * `:long` (`t:String.t/0`) - The long name for the option, it is expected to be provided as `--{long_name}`. If not
    set defaults to the option name itself, casted to string with underscores replaced by dashes. 

      ```cli
      schema = [
        # long not set, it is set to --user-name
        user_name: [type: :string],
        # you can explicitly set a long name with underscores if needed
        another_user_name: [type: :string, long: "another_user_name"]
      ]

      CliOptions.parse!(["--user-name", "John", "--another_user_name", "Jack"], schema)
      ```

    * `:short` (`t:String.t/0`) - An optional short name for the option. It is expected
    to be a single letter string.

      ```cli
      schema = [user_name: [short: "U"]]

      CliOptions.parse!(["-U", "John"], schema)
      ```

    * `:aliases` (list of `t:String.t/0`) - Long aliases for the option. It is expected
    to be a list of strings. 

      ```cli
      schema = [user_name: [aliases: ["user_name"]]]

      # with the default long name
      CliOptions.parse!(["--user-name", "John"], schema)
      >>>

      # with an alias
      CliOptions.parse!(["--user_name", "John"], schema)
      ```

    * `:short_aliases` (list of `t:String.t/0`) - Similar to `:aliases`, but for short names.
    * `:doc` (`t:String.t/0`) - The documentation for the CLI option. Can be any markdown
    string. This will be used in the automatically generate options documentation.
    * `:default` (`t:term/0`) - The default value for the CLI option if that option is not
    provided in the CLI arguments. This is validated according to the given `:type`.

      ```cli
      schema = [user_name: [default: "John"]]

      # with no option provided
      CliOptions.parse!([], schema)
      >>>

      # provided CLI options override the default value
      CliOptions.parse!(["--user-name", "Jack"], schema)
      >>>
      ```

    * `:required` (`t:boolean/0`) - Defines if the option is required or not. An exception
    will be raised if a required option is not provided in the CLI arguments.

    * `:multiple` (`t:boolean/0`) - If set to `true` an option can be provided multiple
    times. Defaults to `false`.

      ```cli
      schema = [project: [multiple: true]]

      CliOptions.parse!(["--project", "foo", "--project", "bar"], schema)
      ```

    * `:allowed` (list of `t:String.t/0`) - A set of allowed values for the option. If any
    other value is given an exception will be raised during parsing.
  """

  @typedoc """
  A `CliOptions.Schema` struct.

  Includes the validated schema and the mapping between option names and options.
  """
  @type t :: %__MODULE__{
          schema: keyword(),
          mappings: %{String.t() => atom()}
        }

  defstruct schema: [], mappings: []

  # validates the schema, rename to new! similar to nimbleoptiosn
  @doc """
  Validates the schema.

  ## Examples

      iex> CliOptions.Schema.new!([name: [type: :string, short: "U"], vebose: [type: :boolean]])
      %CliOptions.Schema{
        schema: [
          name: [short_aliases: [], aliases: [], long: "name", type: :string, short: "U"],
          vebose: [default: false, short_aliases: [], aliases: [], long: "vebose", type: :boolean]
        ],
        mappings: %{"U" => :name, "name" => :name, "vebose" => :vebose}
      }

      iex> CliOptions.Schema.new!([name: [type: :invalid]])
      ** (ArgumentError) invalid schema for :name, invalid type :invalid
  """
  @spec new!(schema :: keyword()) :: t()
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
  @doc false
  @spec validate(opts :: keyword(), schema :: t()) :: {:ok, keyword()} | {:error, String.t()}
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
         :ok <- maybe_validate_allowed_value(option, value, schema[:allowed]),
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

  defp maybe_validate_allowed_value(_option, _value, nil), do: :ok

  defp maybe_validate_allowed_value(option, value, allowed) when is_binary(value) do
    case value in allowed do
      true ->
        :ok

      false ->
        {:error, "invalid value #{inspect(value)} for :#{option}, allowed: #{inspect(allowed)}"}
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

  @doc false
  @spec action(option :: atom(), schema :: t()) :: :negate | :count | :append | :set
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

  @doc false
  @spec ensure_valid_option(option :: atom(), schema :: t()) ::
          {:ok, keyword()} | {:error, String.t()}
  def ensure_valid_option(option, schema) do
    case Map.get(schema.mappings, option) do
      nil -> {:error, "invalid option #{inspect(option)}"}
      option -> {:ok, option, schema.schema[option]}
    end
  end

  @doc false
  @spec expected_args(opts :: keyword()) :: integer()
  def expected_args(opts) do
    cond do
      opts[:type] == :boolean -> 0
      opts[:type] == :counter -> 0
      true -> 1
    end
  end
end
