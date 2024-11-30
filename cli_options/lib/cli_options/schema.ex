defmodule CliOptions.Schema do
  @valid_types [:string, :boolean, :integer, :float, :counter, :atom]

  valid_types_doc = Enum.map_join(@valid_types, ", ", fn x -> "`#{inspect(x)}`" end)

  option_schema = [
    type: [
      type: {:in, @valid_types},
      default: :string,
      doc: """
      The type of the argument. Can be one of #{valid_types_doc}. If not set defaults
      to `:string`.

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
      """
    ],
    default: [
      type: :any,
      doc: """
      The default value for the CLI option if that option is not provided in the CLI
      arguments. This is validated according to the given `:type`.

      ```cli
      schema = [user_name: [default: "John"]]

      # with no option provided
      CliOptions.parse!([], schema)
      >>>

      # provided CLI options override the default value
      CliOptions.parse!(["--user-name", "Jack"], schema)
      >>>
      ```
      """
    ],
    long: [
      type: :string,
      doc: """
      The long name for the option, it is expected to be provided as `--{long_name}`. If
      not set defaults to the option name itself, casted to string with underscores
      replaced by dashes. 

      ```cli
      schema = [
        # long not set, it is set to --user-name
        user_name: [type: :string],
        # you can explicitly set a long name with underscores if needed
        another_user_name: [type: :string, long: "another_user_name"]
      ]

      CliOptions.parse!(["--user-name", "John", "--another_user_name", "Jack"], schema)
      ```
      """
    ],
    short: [
      type: :string,
      doc: """
      An optional short name for the option. It is expected to be a single letter string.

      ```cli
      schema = [user_name: [short: "U"]]

      CliOptions.parse!(["-U", "John"], schema)
      ```
      """
    ],
    aliases: [
      type: {:list, :string},
      doc: """
      Long aliases for the option. It is expected to be a list of strings. 

      ```cli
      schema = [user_name: [aliases: ["user_name"]]]

      # with the default long name
      CliOptions.parse!(["--user-name", "John"], schema)
      >>>

      # with an alias
      CliOptions.parse!(["--user_name", "John"], schema)
      ```
      """,
      default: []
    ],
    short_aliases: [
      type: {:list, :string},
      doc: "Similar to `:aliases`, but for short names.",
      default: []
    ],
    doc: [
      type: {:or, [:string, {:in, [false]}]},
      type_doc: "`t:String.t/0` or `false`",
      doc: """
      The documentation for the CLI option. Can be any markdown string. This will be
      used in the automatically generated options documentation. If set to `false`
      then the option will not be included in the generated docs.
      """
    ],
    doc_section: [
      type: :atom,
      doc: """
      The section in the documentation this option will be put under. If not set the
      option is added to the default unnamed section. If set you must also provide the
      `:sections` option in the `CliOptions.docs/2` call.
      """
    ],
    required: [
      type: :boolean,
      doc: """
      Defines if the option is required or not. An exception will be raised if a required
      option is not provided in the CLI arguments.
      """,
      default: false
    ],
    multiple: [
      type: :boolean,
      doc: """
      If set to `true` an option can be provided multiple times.

      ```cli
      schema = [project: [multiple: true]]

      CliOptions.parse!(["--project", "foo", "--project", "bar"], schema)
      ```
      """,
      default: false
    ],
    separator: [
      type: :string,
      doc: """
      An optional separator for passing multiple values with the same cli
      argument. Applicable only if `multiple` is set to `true`.

      ```cli
      schema = [project: [multiple: true, separator: ";"]]

      # passing the projects multiple times
      CliOptions.parse!(["--project", "foo", "--project", "bar"], schema)
      >>>

      # using a separator
      CliOptions.parse!(["--project", "foo;bar"], schema)
      >>>

      # using a separator and passing the argument multiple times
      CliOptions.parse!(["--project", "foo;bar", "--project", "baz;fan"], schema)
      ```
      """
    ],
    allowed: [
      type: {:list, :string},
      doc: """
      A set of allowed values for the option. If any other value is given an exception
      will be raised during parsing.
      """
    ],
    deprecated: [
      type: :string,
      doc: """
      Defines a message to indicate that the option is deprecated. The message will
      be displayed as a warning when passing the item.
      """
    ],
    env: [
      type: :string,
      doc: """
      An environment variable to get this option from, if it is missing from the command
      line arguments. If the option is provided by the user the environment variable
      is ignored.

      For boolean options, the flag is considered set if the environment variable has
      a truthy value (`1`, `true`) and ignored in any other case.
      """
    ],
    conflicts_with: [
      type: {:list, :atom},
      doc: """
      List of conflicting options. If set this argument will be mutually exclusive with
      any of the specified arguments.
      """
    ]
  ]

  @schema NimbleOptions.new!(option_schema)

  @moduledoc """
  The schema for command line options.

  ## Schema Options

  The following are the options supported in a schema. They are used for validating
  passed command line arguments:

  #{NimbleOptions.docs(@schema)}
  """

  @typedoc """
  A `CliOptions.Schema` struct.

  Includes the validated schema and the mapping between option names and options.
  """
  @type t :: %__MODULE__{
          schema: keyword(),
          long_mappings: %{String.t() => atom()},
          short_mappings: %{String.t() => atom()}
        }

  defstruct schema: [], long_mappings: [], short_mappings: []

  @doc false
  @spec schema() :: keyword()
  def schema, do: @schema

  @doc """
  Validates the schema.

  ## Examples

      iex> CliOptions.Schema.new!([name: [type: :string, short: "U"], verbose: [type: :boolean]])
      %CliOptions.Schema{
        schema: [
          name: [long: "name", multiple: false, required: false, short_aliases: [], aliases: [], type: :string, short: "U"],
          verbose: [long: "verbose", default: false, multiple: false, required: false, short_aliases: [], aliases: [], type: :boolean]
        ],
        long_mappings: %{"name" => :name, "verbose" => :verbose},
        short_mappings: %{"U" => :name}
      }

      iex> CliOptions.Schema.new!([name: [type: :invalid]])
      ** (ArgumentError) invalid schema for :name, invalid value for :type option: expected one of [:string, :boolean, :integer, :float, :counter, :atom], got: :invalid
  """
  @spec new!(schema :: keyword()) :: t()
  def new!(schema) do
    if not Keyword.keyword?(schema) do
      raise ArgumentError, "schema was expected to be a keyword list, got: #{inspect(schema)}"
    end

    schema = validate_schema!(schema)
    long_mappings = build_mappings(schema, &long_mappings/1)
    short_mappings = build_mappings(schema, &short_mappings/1)

    %__MODULE__{schema: schema, long_mappings: long_mappings, short_mappings: short_mappings}
  end

  defp validate_schema!(schema) do
    for {option, opts} <- schema do
      validate_option_schema!(option, opts)
    end
  end

  defp validate_option_schema!(option, opts) do
    with {:ok, opts} <- validate_nimble_schema(opts),
         {:ok, opts} <- validate_default_value(opts),
         {:ok, opts} <- validate_conflicting_options(opts) do
      opts = Keyword.put_new(opts, :long, default_long_name(option))
      {option, opts}
    else
      {:error, reason} -> raise ArgumentError, "invalid schema for :#{option}, #{reason}"
    end
  end

  defp validate_nimble_schema(opts) do
    case NimbleOptions.validate(opts, @schema) do
      {:ok, opts} -> {:ok, opts}
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
    end
  end

  defp default_long_name(option), do: Atom.to_string(option) |> String.replace("_", "-")

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

  defp validate_conflicting_options(opts) do
    validate_separator(opts)
  end

  defp validate_separator(opts) do
    if opts[:separator] && !opts[:multiple] do
      {:error, "you are not allowed to set separator if multiple is set to false"}
    else
      {:ok, opts}
    end
  end

  defp build_mappings(schema, mappings_function) do
    mappings = %{}

    for {option, opts} <- schema, mapping <- mappings_function.(opts), reduce: mappings do
      mappings when is_map_key(mappings, mapping) ->
        raise ArgumentError,
              "mapping #{mapping} for option :#{option} is already defined for :#{mappings[mapping]}"

      mappings ->
        Map.put(mappings, mapping, option)
    end
  end

  defp long_mappings(opts) do
    [
      opts[:long]
    ]
    |> Enum.concat(opts[:aliases])
    |> Enum.reject(&is_nil/1)
  end

  defp short_mappings(opts) do
    [
      opts[:short]
    ]
    |> Enum.concat(opts[:short_aliases])
    |> Enum.reject(&is_nil/1)
  end

  # opts is expected to be a keyword of the form [option: args]
  # where args a list of the specified args for this option or a single arg
  @doc false
  @spec validate(opts :: keyword(), schema :: t()) :: {:ok, keyword()} | {:error, String.t()}
  def validate(opts, schema) do
    with {:ok, opts} <- validate_options(opts, schema),
         :ok <- validate_mutually_exclusive(opts, schema) do
      {:ok, opts}
    end
  end

  defp validate_options(opts, schema) do
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
         :ok <- maybe_validate_allowed_value(option, value, schema[:allowed]) do
      validate_type(option_type(schema), option, value)
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
  @spec action(option :: atom(), schema :: keyword()) :: :negate | :count | :append | :set
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
  @spec ensure_valid_option(option :: String.t(), short_or_long :: :long | :short, schema :: t()) ::
          {:ok, atom(), keyword()} | {:error, String.t()}
  def ensure_valid_option(option, short_or_long, schema) do
    case short_or_long_get(option, short_or_long, schema) do
      nil -> {:error, "invalid option #{inspect(option)}"}
      option -> {:ok, option, schema.schema[option]}
    end
  end

  defp short_or_long_get(option, :long, schema), do: Map.get(schema.long_mappings, option)
  defp short_or_long_get(option, :short, schema), do: Map.get(schema.short_mappings, option)

  @doc false
  @spec expected_args(opts :: keyword()) :: integer()
  def expected_args(opts) do
    cond do
      opts[:type] == :boolean -> 0
      opts[:type] == :counter -> 0
      true -> 1
    end
  end

  defp validate_mutually_exclusive(opts, schema) do
    Enum.reduce_while(opts, :ok, fn {option, _value}, _acc ->
      conflicts_with = schema.schema[option][:conflicts_with]

      case conflicts_with do
        nil ->
          {:cont, :ok}

        conflicts_with ->
          conflicts = Enum.filter(conflicts_with, &Keyword.has_key?(opts, &1))

          case conflicts do
            [] ->
              {:cont, :ok}

            conflicts ->
              conflicts =
                Enum.map_join(conflicts, ", ", fn conflict -> long_name_cli(schema, conflict) end)

              {:halt,
               {:error,
                "#{long_name_cli(schema, option)} is mutually exclusive with #{conflicts}"}}
          end
      end
    end)
  end

  defp long_name_cli(schema, option), do: "--" <> schema.schema[option][:long]
end
