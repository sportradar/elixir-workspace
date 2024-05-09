defmodule CliOptions.Schema.Validation do
  @moduledoc false
  # Schema validation

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
      type: :string,
      doc: """
      The documentation for the CLI option. Can be any markdown string. This will be
      used in the automatically generate options documentation.
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
    allowed: [
      type: {:list, :string},
      doc: """
      A set of allowed values for the option. If any other value is given an exception
      will be raised during parsing.
      """
    ]
  ]

  @schema NimbleOptions.new!(option_schema)

  @spec schema() :: keyword()
  def schema, do: @schema

  @doc """
  Validates that the given keyword list is a valid schema.

  Raises an `ArgumentError` if the schema is invalid.
  """
  @spec validate!(schema :: keyword()) :: keyword()
  def validate!(schema) do
    for {option, opts} <- schema do
      validate_option!(option, opts)
    end
  end

  defp validate_option!(option, opts) do
    with {:ok, opts} <- validate_nimble_schema(opts),
         {:ok, opts} <- validate_default_value(opts) do
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
end
