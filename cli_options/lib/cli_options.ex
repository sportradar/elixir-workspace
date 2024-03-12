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

  The main function of this module is `parse/3` which parses a list
  of command line options and arguments into a `CliOptions.Options` struct.
  It expects an `argv` string list and the options schema.

  ```cli
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

  CliOptions.parse(["--foo", "bar"], schema)
  >>>

  CliOptions.parse(["--foo", "bar", "-n", 2, "foo.ex"], schema)
  >>>

  CliOptions.parse(["--foo", "bar", "-n", 2, "file.txt", "--", "-n", "1"], schema)
  >>>
  ```

  Alternatively you can pass `as_tuple: true` to the `opts` which will return a tuple
  of the form `{parsed, args, extra}`.

  ```cli
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

  CliOptions.parse(["--foo", "bar"], schema, as_tuple: true)
  >>>

  CliOptions.parse(["--foo", "bar", "-n", 2, "foo.ex"], schema, as_tuple: true)
  >>>

  CliOptions.parse(
    ["--foo", "bar", "-n", 2, "file.txt", "--", "-n", "1"],
    schema,
    as_tuple: true
  )
  >>>
  ```
  """

  @type argv :: [String.t()]

  @type parsed :: keyword()

  @type extra :: [String.t()]

  @doc """
  Parses `argv` according to the provided `schema`.

  By default a `CliOptions.Options` struct is returned, which contains the following:

    * `argv` - the input `argv` string list
    * `schema` - the schema used for validation
    * `opts` - the extracted command line options
    * `args` - a list of the remaining arguments in `argv` as strings
    * `extra` - a list of unparsed arguments, if applicable.

  ## Options names and aliases

  By default `CliOptions` will use the hyphen-ized version of the option name
  as the long name of the option.

  ```cli
  {:ok, options} = CliOptions.parse(["--user-name", "John"], [user_name: [type: :string]])
  options.opts
  ```

  Additionally you are allowed to set a short version (one-letter string) for the
  option.

  ```cli
  {:ok, options} = CliOptions.parse(["-U", "John"], [user_name: [type: :string, short: "U"]])
  options.opts
  ```

  You are also allowed to specifically set a long name for the option. In this case the
  auto-generated long name from the option name will not valid.


  ```cli
  CliOptions.parse(["-U", "John"], [user_name: [type: :string, long: "user"]])
  >>>

  {:ok, options} =
    CliOptions.parse(
      ["--user", "John"],
      [user_name: [type: :string, long: "user"]]
    )
  options.opts
  >>>
  ```

  Additionally you can provide an arbitrary number of long and short aliases.

  ```cli
  schema = [
    user_name: [
      type: :string,
      short: "u",
      aliases: ["user", "user_name"],
      short_aliases: ["U"]
    ]
  ]

  # all following argv are equivalent
  inputs = [
    ["--user-name", "John"],
    ["--user", "John"],
    ["--user_name", "John"],
    ["-u", "John"],
    ["-U", "John"]
  ]

  for argv <- inputs, options = CliOptions.parse!(argv, schema) do
    options.opts == [user_name: "John"]
  end
  |> Enum.all?()
  ```

  > #### Strict parsing by default {: .warning}
  >
  > Notice that `CliOptions` will return an error if a not expected option is
  > encountered. Only options defined in the provided schema are allowed. If you
  > need to support arbitrary options you will have to add them after the return
  > separator and handle them in your application code.
  >
  > ```cli
  > schema = [
  >   file: [
  >     type: :string,
  >     required: true 
  >   ],
  >   number: [
  >     type: :integer,
  >     short: "n"
  >   ] 
  > ]
  >
  > # parses valid arguments
  > CliOptions.parse(["--file", "foo.ex", "-n", "2"], schema, as_tuple: true)
  > >>>
  >
  > # error if invalid argument is encountered
  > CliOptions.parse(["--file", "foo.ex", "-b", "2"], schema, as_tuple: true)
  > >>>
  >
  > # you can add extra arguments after the return separator
  > CliOptions.parse(["--file", "foo.ex", "--", "-b", "2"], schema, as_tuple: true)
  > >>>
  > ```

  ## Option types

  By default all options are assumed to be strings. If you set a different `:type` then
  the option will be casted to that type. The supported types are:

  * `:integer` - parses the argument as an integer
  * `:float` - parses the argument as a float
  * `:string` - the default, parses the argument as a string
  * `:boolean` - parses the argument as a flag, e.g. no option is expected.

  ```cli
  schema = [
    user: [
      type: :string,
    ],
    age: [
      type: :integer,
    ],
    height: [
      type: :float,
    ]
  ]

  {:ok, options} =
    CliOptions.parse(
      ["--user", "John", "--age", "34", "--height", "1.75"],
      schema
    )
  options.opts
  ```

  ## Counters

  In some command line applications you may want to count how many times an option is given. In
  this case no option argument is expected. Instead every time the option is encountered a counter
  is incremented. You can define such an option by setting the type to `:counter`.

  ```cli
  schema = [
    verbosity: [
      type: :counter,
      short: "v"
    ]
  ]

  # counts the number -v flag is given
  {:ok, options} = CliOptions.parse(["-v", "-v", "-v"], schema)
  options.opts
  >>>

  # if not set it is set to zero
  {:ok, options} = CliOptions.parse([], schema)
  options.opts
  >>>
  ```

  ## Default values and required options

  Options can have default values. If no command line argument is provided then the parsed
  options will return the default value instead. For example:

  TODO: example

  > #### Booleans and counters {: .info}
  >
  > Notice that for options of type `:boolean` or `:counter` a default value is always
  > implicitly set.
  >
  > TODO: example

  Additionally you can mark an option as required. In this case an error will be returned if
  the option is not present in the command line arguments.

  ## Options with multiple arguments

  If you want to pass a cli option multiple times you can set the `:multiple` option set to
  `true`. In this case every time the option is encountered the value will be appended to
  the previously encountered values.

  ```cli
  schema = [
    file: [
      type: :string,
      multiple: true,
      short: "f"
    ],
    number: [
      type: :integer,
      multiple: true,
      short: "n"
    ]
  ]

  # all file values are appended to the file option
  {:ok, options} = CliOptions.parse(["-f", "foo.ex", "--file", "bar.ex", "-n", "1", "-n", "2"], schema)
  options.opts
  >>>

  # notice that if an argument is passed once, the value will still be a list
  {:ok, options} = CliOptions.parse(["-f", "foo.ex"], schema)
  options.opts
  >>>

  # all passed items are validated based on the expected type 
  CliOptions.parse(["-n", "2", "-n", "xyz"], schema)
  >>>

  # if multiple is not set then an error is returned if an option is passed twice
  CliOptions.parse(["--file", "foo.ex", "--file", "xyz.ex"], [file: [type: :string]])
  >>>
  ```

  ## Return separator

  The separator `--` implies options should no longer be processed. Every argument
  after the return separator will be added in the `extra` field of the response.

  ```cli
  CliOptions.parse!(["--", "lib", "-n"], [])
  ```

  Notice that if the remaining arguments contain another return separator this will
  included in the extra:

  ```cli
  CliOptions.parse!(["--", "lib", "-n", "--", "bar"], [])
  ```
  """
  @spec parse(argv :: argv(), schema :: keyword(), opts :: keyword()) ::
          {:ok, CliOptions.Options.t() | {parsed(), argv(), extra()}} | {:error, String.t()}
  def parse(argv, schema, opts \\ []) do
    case CliOptions.Parser.parse(argv, schema) do
      {:ok, options} -> {:ok, format_options(options, opts[:as_tuple])}
      {:error, reason} -> {:error, reason}
    end
  end

  defp format_options(options, true), do: {options.opts, options.args, options.extra}
  defp format_options(options, _as_tuple), do: options

  @doc """
  Similar as `parse/2` but raises an `CliOptions.ParseError` exception if invalid
  CLI arguments are given.

  If there are no errors the `CliOptions.Options` struct with the parsed arguments is returned.

  ## Examples

      iex> CliOptions.parse!(["--file", "foo.ex"], [file: [type: :string]], as_tuple: true)
      {[file: "foo.ex"], [], []}

      iex> CliOptions.parse!([], [file: [type: :string, required: true]], as_tuple: true)
      ** (CliOptions.ParseError) option :file is required
  """
  @spec parse!(argv :: argv(), schema :: keyword(), opts :: keyword()) :: CliOptions.Options.t()
  def parse!(argv, schema, opts \\ []) do
    case parse(argv, schema, opts) do
      {:ok, options} -> options
      {:error, reason} -> raise CliOptions.ParseError, reason
    end
  end

  def docs(schema, opts \\ []), do: CliOptions.Schema.Docs.generate(schema, opts)
end
