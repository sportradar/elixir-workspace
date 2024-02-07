defmodule CliOpts do
  @moduledoc """
  A tiny library for parsing and validating CLI options.

  `CliOpts` allows developers to define a schema for the options of command
  line tasks. Among other it offers:

    * Standard schema for defining options
    * Support for required options
    * Initialization of options with default values
    * Handling of aliases
    * Propagates extra arguments (everything under a `--`) 
    * Automatic doc generation

  ## Schema options

  The schema of the cli options is expected to be a keyword list where each
  key is an atom defining the name of the option and the value is a keyword
  list that can contain the following options:

    * `:type` (`atom/0`) - The type of the option, e.g. `:string`, `:boolean` or
    `:integer`. The types supported by `OptionParser` can be used.
    * `:alias` (`atom/0`) - If set defines an alias for the given option.
    * `:required` (`boolean/0`) - Defines if the option is required. The default
    value is `false`
    * `:doc` (`String.t()`) - A short description of the option item
    * `:keep` (`boolean/0`) - If set this option can be used multiple times. The
    default value is `false`
    * `:allowed` (`[String.t()]`) - If set a list of allowed values.
    * `:as` (`atom/0`) - If set the option will be renamed to this value internally.
    This is useful for semantic mapping of options, for example an option
    `:select` with `:keep` set to `true` can be mapped to `:selected`.

  ## Example

  ```elixir
  options = [
    ignore: [
      type: :string,
      alias: :i,
      keep: true,
      doc: "Ignore the given file",
      as: :selected
    ],
    task: [
      type: :string,
      alias: :t,
      doc: "The task to execute",
      required: true
    ],
    verbose: [
      type: :boolean,
      doc: "If set enables verbose logging"
    ]
  ```
  """

  @type argv :: [String.t()]

  @type parsed_options :: %{
          parsed: keyword(),
          args: [String.t()],
          invalid: [{String.t(), String.t() | nil}],
          extra: [String.t()]
        }

  @doc """
  Parses `argv` into a keyword list using the given `schema`

  In case of success it returns `{:ok, result}` where `result` is a map
  with the following keys:

    . `:parsed` - a keyword list with parsed options
    . `:args` - a list of the remaining arguments in `argv` as strings
    . `:invalid` - a list of invalid options (check `OptionParser.parse/2` docs for
    more details)
    . `:extra` - a list of extra arguments. An option is considered extra if
    it appears after a return separator `--` (see the Examples section below
    for more information)

  In case of `error`, e.g. when a required option is missing an error tuple is
  returned

  ## Examples

      iex> CliOpts.parse(["--verbose"], [verbose: [type: :boolean]])
      {:ok, %{parsed: [verbose: true], args: [], extra: [], invalid: []}}

      iex> CliOpts.parse(["--verbose"], [verbose: [type: :boolean], mode: [type: :string, default: "top-down"]])
      {:ok, %{parsed: [mode: "top-down", verbose: true], args: [], extra: [], invalid: []}}

      iex> CliOpts.parse(["--verbose", "file1", "file2"], [verbose: [type: :boolean]])
      {:ok, %{parsed: [verbose: true], args: ["file1", "file2"], extra: [], invalid: []}}

      iex> CliOpts.parse(["--verbose", "-i"], [verbose: [type: :boolean]])
      {:ok, %{parsed: [verbose: true], args: [], extra: [], invalid: [{"-i", nil}]}}

      iex> CliOpts.parse(["-f", "file1", "-f", "file2"], [file: [type: :string, alias: :f, keep: true, as: :files]])
      {:ok, %{parsed: [files: ["file1", "file2"]], args: [], extra: [], invalid: []}}

      iex> CliOpts.parse(["--verbose", "--", "--other", "file"], [verbose: [type: :boolean]])
      {:ok, %{parsed: [verbose: true], args: [], extra: ["--other", "file"], invalid: []}}

      iex> CliOpts.parse([], [file: [type: :string, required: true]])
      {:error, "the following required options were not provided [:file]"}

  """
  @spec parse(argv :: argv(), schema :: Keyword.t()) ::
          {:ok, parsed_options()} | {:error, String.t()}
  def parse(argv, schema) do
    {argv, extra} = split_argv(argv)

    {parsed, args, invalid} =
      OptionParser.parse(argv, strict: switches(schema), aliases: aliases(schema))

    with {:ok, parsed} <- check_required(parsed, schema),
         parsed <- set_defaults(parsed, schema),
         parsed <- update_multiples(parsed, schema),
         {:ok, parsed} <- check_allowed(parsed, schema) do
      {:ok,
       %{
         parsed: maybe_rename(parsed, schema),
         args: args,
         invalid: invalid,
         extra: extra
       }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  The same as `parse/2` but raises on `OptionParser.ParseError` exception if
  any invalid options are given.

  ## Examples

      iex> CliOpts.parse!(["--verbose"], [verbose: [type: :boolean]])
      %{parsed: [verbose: true], args: [], extra: [], invalid: []}

      iex> CliOpts.parse!(["--verbose", "-i"], [verbose: [type: :boolean]])
      ** (OptionParser.ParseError) 1 error found!
      -i : Unknown option

      iex> CliOpts.parse!([], [file: [type: :string, required: true]])
      ** (OptionParser.ParseError) the following required options were not provided [:file]
  """
  @spec parse!(argv :: argv(), schema :: Keyword.t()) :: parsed_options()
  def parse!(argv, schema) do
    case parse(argv, schema) do
      {:ok, %{invalid: invalid} = result} ->
        case invalid do
          [] -> result
          # just pass it again to OptionParser in order to format the errors
          # properly
          _errors -> OptionParser.parse!(argv, strict: switches(schema), aliases: aliases(schema))
        end

      {:error, reason} ->
        raise OptionParser.ParseError, reason
    end
  end

  defp maybe_rename(opts, schema) do
    Enum.reduce(opts, [], fn {name, value}, acc ->
      case schema[name][:as] do
        nil -> [{name, value} | acc]
        as -> [{as, value} | acc]
      end
    end)
    |> Enum.reverse()
  end

  @doc ~S'''
  Returns documentation for the given CLI options schema.

  You can use this to inject documentation in your mix tasks docstrings, for
  example say you have a schema defined in a module attribute:

      @task_opts_schema [...]

  You can use `docs/1` to inject documentation:

      @moduledoc """
      ...

      ## CLI Options

      #{CliOpts.docs(@task_opts_schema)}
      """
  '''
  @spec docs(schema :: Keyword.t(), opts :: keyword()) :: String.t()
  def docs(schema, opts \\ []) when is_list(schema), do: CliOpts.Docs.generate(schema, opts)

  defp switches(schema) do
    schema
    |> Enum.map(fn {key, config} -> {key, switch_type(config)} end)
    |> Keyword.new()
  end

  defp switch_type(schema) do
    type = Keyword.fetch!(schema, :type)

    case schema[:keep] do
      true -> [type, :keep]
      _other -> type
    end
  end

  defp aliases(schema) do
    schema
    |> Enum.map(fn {key, config} -> {config[:alias], key} end)
    |> Enum.filter(fn {alias, _key} -> alias != nil end)
    |> Keyword.new()
  end

  defp split_argv(argv) do
    case Enum.find_index(argv, fn x -> x == "--" end) do
      nil -> {argv, []}
      index -> {Enum.slice(argv, 0..(index - 1)), Enum.slice(argv, (index + 1)..-1//1)}
    end
  end

  defp check_required(args, schema) do
    schema
    |> Enum.filter(fn {_key, opts} -> Keyword.get(opts, :required, false) == true end)
    |> Enum.reduce([], fn {key, _opts}, acc ->
      case Keyword.has_key?(args, key) do
        true -> acc
        false -> [key | acc]
      end
    end)
    |> then(fn missing ->
      case missing do
        [] ->
          {:ok, args}

        missing ->
          {:error, "the following required options were not provided #{inspect(missing)}"}
      end
    end)
  end

  defp set_defaults(args, schema) do
    Enum.reduce(schema, args, fn {key, key_opts}, acc ->
      case key_opts[:default] do
        nil -> acc
        value -> Keyword.put_new(acc, key, value)
      end
    end)
  end

  defp update_multiples(args, schema) do
    Enum.reduce(schema, args, fn {key, key_opts}, acc ->
      case Keyword.get(key_opts, :keep, false) do
        true -> Keyword.put(acc, key, Keyword.get_values(acc, key))
        false -> acc
      end
    end)
  end

  defp check_allowed(args, schema) do
    errors =
      Enum.reduce(args, [], fn {key, value}, errors ->
        allowed = schema[key][:allowed]

        cond do
          is_nil(allowed) ->
            errors

          value not in allowed ->
            [
              "not allowed value #{value} for #{key}, expected one of: #{inspect(allowed)}"
              | errors
            ]

          true ->
            errors
        end
      end)

    case errors do
      [] -> {:ok, args}
      errors -> {:error, Enum.join(errors, "\n")}
    end
  end
end
