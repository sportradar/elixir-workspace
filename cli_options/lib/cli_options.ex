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
  of command line options and arguments into a tuple of parsed options,
  positional arguments and extra options (anything passed after the `--`
  separator).

  ```cli
  schema = [
    name: [
      type: :string,
      required: true 
    ],
    num: [
      type: :integer,
      default: 4,
      short: "n"
    ] 
  ]

  CliOptions.parse(["--name", "foo"], schema)
  >>>

  # with positional arguments
  CliOptions.parse(["--name", "foo", "-n", "2", "foo.ex"], schema)
  >>>

  # with positional arguments and extra options
  CliOptions.parse(["--name", "foo", "-n", "2", "file.txt", "--", "-n", "1"], schema)
  >>>

  # with invalid options
  CliOptions.parse(["--user-name", "foo"], schema)
  ```

  Check the `parse/2` documentation for more details.

  > #### Strict validation {: .warning}
  >
  > Notice that `CliOptions` adheres to a strict options validation approach. This
  > means that an error will be returned in any of the following cases:
  >
  > - An invalid option is provided
  > - An option is provided more times than expected
  > - The option's type is not valid
  > - A required option is not provided
  >
  > ```cli
  > schema = [
  >   number: [type: :integer],
  >   name: [type: :string, required: true]
  > ]
  >
  > # with invalid option
  > CliOptions.parse(["--name", "foo", "--invalid"], schema)
  > >>>
  >
  > # with missing required option
  > CliOptions.parse([], schema)
  > >>>
  >
  > # with invalid type
  > CliOptions.parse(["--name", "foo", "--number", "asd"], schema)
  > >>>
  >
  > # with option re-definition
  > CliOptions.parse(["--name", "foo", "--name", "bar"], schema)
  > ```
  """

  @type argv :: [String.t()]
  @type options :: keyword()
  @type extra :: [String.t()]

  @type parsed_options :: {options(), argv(), extra()}

  @doc """
  Parses `argv` according to the provided `schema`.

  `schema` can be either a `CliOptions.Schema` struct, or a keyword list. In
  the latter case it will be first initialized to a `CliOptions.Schema`.

  If the provided CLI arguments are valid, then an `{:ok, parsed}` tuple is
  returned, where `parsed` is a three element tuple of the form `{opts, args, extra}`,
  where:

    * `opts` - the extracted command line options
    * `args` - a list of the remaining arguments in `argv` as strings
    * `extra` - a list of unparsed arguments, if applicable.

  If validation fails, an `{:error, message}` tuple will be returned.

  > #### Creating the schema at compile time {: .tip}
  >
  > To avoid the extra cost of initializing the schema, it is possible to create
  > the schema once, and then use that valid schema directly. This is done by
  > using the `CliOptions.Schema.new!/1` function first, and then passing the
  > returned schema to `parse/2`.
  >
  > Usually you will define the schema as a module attribute and then use it in
  > your mix task.
  >
  > ```elixir
  > defmodule Mix.Tasks.MyTask do
  >   use Mix.Task
  >
  >   schema = [
  >     user_name: [type: :string],
  >     verbose: [type: :boolean]
  >   ]
  >
  >   @schema CliOptions.Schema.new!(schema)
  >
  >   @impl Mix.Task
  >   def run(argv) do
  >     {opts, args, extra} = CliOptions.parse!(args, @schema)
  >    
  >     # your task code here
  >   end
  > end
  > ```


  ## Options names and aliases

  By default `CliOptions` will use the hyphen-ized version of the option name
  as the long name of the option.

  ```cli
  CliOptions.parse(["--user-name", "John"], [user_name: [type: :string]])
  ```

  Additionally you are allowed to set a short version (one-letter string) for the
  option.

  ```cli
  CliOptions.parse(["-U", "John"], [user_name: [type: :string, short: "U"]])
  ```

  You are also allowed to specifically set a long name for the option. In this case the
  auto-generated long name from the option name will not valid.


  ```cli
  CliOptions.parse(["-U", "John"], [user_name: [type: :string, long: "user"]])
  >>>

  CliOptions.parse(
    ["--user", "John"],
    [user_name: [type: :string, long: "user"]]
  )
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

  for argv <- inputs, {opts, [], []} = CliOptions.parse!(argv, schema) do
    opts == [user_name: "John"]
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
  > CliOptions.parse(["--file", "foo.ex", "-n", "2"], schema)
  > >>>
  >
  > # error if invalid argument is encountered
  > CliOptions.parse(["--file", "foo.ex", "-b", "2"], schema)
  > >>>
  >
  > # you can add extra arguments after the return separator
  > CliOptions.parse(["--file", "foo.ex", "--", "-b", "2"], schema)
  > ```

  ## Option types

  By default all options are assumed to be strings. If you set a different `:type` then
  the option will be casted to that type. The supported types are:

  * `:string` - the default, parses the argument as a string
  * `:integer` - parses the argument as an integer
  * `:float` - parses the argument as a float
  * `:atom` - converts the arguments to atoms
  * `:boolean` - parses the argument as a flag, e.g. no option is expected.
  * `:counter` - treats the argument as a flag that increases an associated counter

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
  options
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
  CliOptions.parse(["-v", "-v", "-v"], schema)
  >>>

  # if not set it is set to zero
  CliOptions.parse([], schema)
  ```

  ## Default values and required options

  Options can have default values. If no command line argument is provided then the parsed
  options will return the default value instead. For example:

  ```cli
  schema = [
    verbose: [
      type: :boolean,
      default: true
    ],
    retries: [
      type: :integer,
      default: 1
    ] 
  ]

  CliOptions.parse([], schema)
  ```

  > #### Booleans and counters {: .info}
  >
  > Notice that for options of type `:boolean` or `:counter` a default value is always
  > implicitly set.
  >
  > ```cli
  > schema = [verbose: [type: :boolean], level: [type: :counter]]
  >
  > CliOptions.parse([], schema)
  > ```

  Additionally you can mark an option as required. In this case an error will be returned if
  the option is not present in the command line arguments.

  ```cli
  schema = [file: [type: :string, required: true]]

  CliOptions.parse([], schema)
  >>>

  CliOptions.parse(["--file", "foo.ex"], schema)
  >>>
  ```

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
  CliOptions.parse(["-f", "foo.ex", "--file", "bar.ex", "-n", "1", "-n", "2"], schema)
  >>>

  # notice that if an argument is passed once, the value will still be a list
  CliOptions.parse(["-f", "foo.ex"], schema)
  >>>

  # all passed items are validated based on the expected type 
  CliOptions.parse(["-n", "2", "-n", "xyz"], schema)
  >>>

  # if multiple is not set then an error is returned if an option is passed twice
  CliOptions.parse(["--file", "foo.ex", "--file", "xyz.ex"], [file: [type: :string]])
  ```

  Additionally you can specify the `:separator` option which allows you to pass
  multiple values grouped together instead of providing the same option multiple
  times. **Notice that this is applicable only if `:multiple` is set to `true`.**

  ```cli
  schema = [
    project: [
      type: :string,
      multiple: true,
      separator: ",",
      short: "p"
    ]
  ]

  # pass all values grouped with the separator
  CliOptions.parse(["-p", "foo,bar,baz"], schema)
  >>>

  # you are still free to pass the `-p` flag multiple times
  CliOptions.parse(["-p", "foo,bar", "-p", "baz"], schema)
  >>>
  ```

  ## Environment variable aliases

  You can optionally define an environment variable alias for an option through the
  `:env` schema option. If set the environment variable will be used **only if** the
  argument is not present in the `args`.

  ```cli
  schema = [
    mode: [
      type: :string,
      env: "CLI_OPTIONS_MODE"
    ]
  ]

  # assume the environment variable is set
  System.put_env("CLI_OPTIONS_MODE", "parallel")

  # if the argument is provided by the user the environment variable is ignored
  CliOptions.parse(["--mode", "sequential"], schema)
  >>>

  # the environment variable will be used if not set
  CliOptions.parse([], schema)
  >>>

  System.delete_env("CLI_OPTIONS_MODE")
  ```

  > #### Boolean flags and environment variables {: .warning}
  >
  > Notice that if the option is `:boolean` and an `:env` alias is set, then the
  > environment variable will be used only if it has a _truthy_ value. A value is
  > considered truthy if it is one of `1`, `true` (the match is case insensitive).
  > In any other case the environment variable is ignored.
  >
  > ```cli
  > schema = [
  >   enable: [type: :boolean, env: "CLI_OPTIONS_ENABLE"]
  > ]
  >
  > System.put_env("CLI_OPTIONS_ENABLE", "1")
  > CliOptions.parse([], schema)
  > >>>
  >
  > System.put_env("CLI_OPTIONS_ENABLE", "TrUE")
  > CliOptions.parse([], schema)
  > >>>
  >
  > System.put_env("CLI_OPTIONS_ENABLE", "other")
  > CliOptions.parse([], schema)
  > >>>
  >
  > System.delete_env("CLI_OPTIONS_ENABLE")
  > ```

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

  ## Post validation

  In some cases you may need to perform more complex validation on the provided
  CLI arguments that cannot be performed by the parser itself. You could do it
  directly in your codebase but for your convenience `CliOptions.parse/2` allows
  you to pass an optional `:post_validate` argument. This is expected to be a
  function having as input the parsed options and expected to return an
  `{:ok, parsed_options()}` or an `{:error, String.t()}` tuple.

  Let's see an example:

  ```cli
  schema = [
    silent: [type: :boolean],
    verbose: [type: :boolean]
  ]

  # the flags --verbose and --silent should not be set together
  post_validate =
    fn {opts, args, extra} ->
      if opts[:verbose] and opts[:silent] do
        {:error, "flags --verbose and --silent cannot be set together"}
      else
        {:ok, {opts, args, extra}}
      end
    end

  # without post_validate
  CliOptions.parse(["--verbose", "--silent"], schema)
  >>>

  # with post_validate
  CliOptions.parse(["--verbose", "--silent"], schema, post_validate: post_validate)
  >>>

  # if only one of the two is passed the validation returns :ok
  CliOptions.parse(["--verbose"], schema, post_validate: post_validate)
  >>>
  ```
  """
  @spec parse(argv :: argv(), schema :: keyword() | CliOptions.Schema.t()) ::
          {:ok, parsed_options()} | {:error, String.t()}
  def parse(argv, schema, opts \\ [])

  def parse(argv, %CliOptions.Schema{} = schema, opts) do
    with {:ok, options} <- CliOptions.Parser.parse(argv, schema) do
      post_validate(options, opts)
    end
  end

  def parse(argv, schema, opts) do
    schema = CliOptions.Schema.new!(schema)
    parse(argv, schema, opts)
  end

  defp post_validate(options, opts) do
    cond do
      opts[:post_validate] && is_function(opts[:post_validate], 1) ->
        opts[:post_validate].(options)

      opts[:post_validate] ->
        {:error,
         "expected :post_validate to be a function of arity 1, got: #{inspect(opts[:post_validate])}"}

      true ->
        {:ok, options}
    end
  end

  @doc """
  Similar as `parse/2` but raises an `CliOptions.ParseError` exception if invalid
  CLI arguments are given.

  If there are no errors an `{opts, args, extra}` tuple is returned.

  ## Examples

      iex> CliOptions.parse!(["--file", "foo.ex"], [file: [type: :string]])
      {[file: "foo.ex"], [], []}

      iex> CliOptions.parse!([], [file: [type: :string, required: true]])
      ** (CliOptions.ParseError) option :file is required
  """
  @spec parse!(argv :: argv(), schema :: keyword() | CliOptions.Schema.t(), opts :: Keyword.t()) ::
          parsed_options()
  def parse!(argv, schema, opts \\ []) do
    case parse(argv, schema, opts) do
      {:ok, options} -> options
      {:error, reason} -> raise CliOptions.ParseError, reason
    end
  end

  @doc """
  Returns documentation for the given schema.

  You can use this to inject documentation in your docstrings. For example,
  say you have your schema in a mix task:

      @options_schema [...]

  With this, you can use `docs/2` to inject documentation:

  ```markdown
  ## Supported Options

  \#{CliOptions.docs(@options_schema)}"
  ```

  ## Options

    * `:sort` - if set to `true` the options will be sorted alphabetically.
    * `:sections` - a keyword list with options sections. If set the options docs
      will be added under the defined section, or at the root section if no
      `:section` is defined in your schema.

      Notice that if `:sort` is set the options
      will be sorted within the sections. The sections order is not sorted and it
      follows the provided order.

      An entry for each section is expected in the `:sections` option with the
      following format:

          [
            section_name: [
              header: "Section Header",
              doc: "Optional extra docs for this docs section"
            ]
          ]

      where:

      * `:header` - The header that will be used for the section. Required.
      * `:doc` - Optional detailed section docs to be added before the actual
      options docs.
  """
  @spec docs(schema :: keyword() | CliOptions.Schema.t(), opts :: keyword()) :: String.t()
  def docs(schema, opts \\ [])

  def docs(%CliOptions.Schema{} = schema, opts), do: CliOptions.Docs.generate(schema, opts)

  def docs(schema, opts) when is_list(schema) do
    schema = CliOptions.Schema.new!(schema)
    docs(schema, opts)
  end
end
