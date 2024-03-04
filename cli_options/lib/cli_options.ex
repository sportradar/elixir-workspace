defmodule CliOptions do
  @moduledoc """
  An opinionated command line arguments parser.

  ## Features

  The main features of `CliOptions` are:

  * Schema based validation of command line arguments.
  * Support for common options types and custom validations.
  * Strict validation by default, an error is returned if an invalid.
  argument is passed.
  * Supports required options, default values, aliases, mutually
  exclusive options and much more (check `CliOptions.Schema` for more
  details).
  * Auto-generated docs for the supported arguments.

  ## Usage

  The main function of this module is `parse/2` which parses a list
  of command line options and arguments into a `CliOptions.Options` struct.
  It expects an `argv` string list and the options schema.

  # TODO: update docs

  ```elixir
  schema = [
    foo: [
      type: :string,
      required: true 
    ],
    num: [
      type: :integer,
      default: 4,
      short: "n"
    ] 
  ]

  iex> CliOptions.parse!(["--foo", "bar"], schema)
  %CliOptions.Options{
    options: [foo: "bar", num: 4]
  }

  iex> CliOptions.parse!(["--foo", "bar", "-n", 2], schema)
  %CliOptions.Options{
    options: [foo: "bar", num: 2]
  }

  iex> CliOptions.parse!(["--foo", "bar", "-n", 2], schema)
  %CliOptions.Options{
    options: [foo: "bar", num: 2]
  }
  ```
  """

  @type argv :: [String.t()]

  @doc """
  Parses `argv` into a `CliOptions.Options` struct.

  The returned struct contains the following:

    * `argv` - the input `argv` string list
    * `schema` - the schema used for validation
    * `opts` - the extracted command line options
    * `args` - a list of the remaining arguments in `argv` as strings
    * `extra` - a list of unparsed arguments, if applicable.

  ## Return separator

  The separator `--` implies options should no longer be processed. Every argument
  after the return separator will be added in the `extra` field of the response.

      iex> CliOptions.parse!(["--", "lib", "-n"], [])
      %CliOptions.Options{
        extra: ["lib", "-n"]
      }

  Notice that if the remaining arguments contain another return separator this will
  included in the extra:

      iex> CliOptions.parse!(["--", "lib", "-n", "--", "bar"], [])
      %CliOptions.Options{
        extra: ["lib", "-n", "--", "bar"]
      }
  """
  @spec parse(argv :: argv(), schema :: keyword()) ::
          {:ok, CliOptions.Options.t()} | {:error, String.t()}
  def parse(argv, schema), do: CliOptions.Parser.parse(argv, schema)

  @doc """
  Similar as `parse/2` but raises an `CliOptions.ParseError` exception if invalid
  CLI arguments are given.

  If there are no errors the `CliOptions.Options` struct with the parsed arguments is returned.

  ## Examples

  TODO: fill it up
  """
  @spec parse!(argv :: argv(), schema :: keyword()) :: CliOptions.Options.t()
  def parse!(argv, schema) do
    case parse(argv, schema) do
      {:ok, options} -> options
      {:error, reason} -> raise CliOptions.ParseError, reason
    end
  end
end
