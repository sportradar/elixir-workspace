# CliOptions

An opinionated command line arguments parser.

`CliOptions` is an alternative to `OptionsParser` that allows you to validate CLI
arguments based on a definition. Out of the box you get a polished CLI experience
including:

  * Support for common options types and custom validations.
  * Strict validation by design, an error is returned if an invalid.
  argument is passed.
  * Supports required options, default values, aliases, mutually
  exclusive options and much more.
  * Auto-generated docs for the supported arguments.

## Usage

A definition is a keyword list specifying among other the expected command line arguments,
their types and aliases. For example:

```elixir
schema = [
  project: [
    type: :string,
    short: "p",
    doc: "The project name",
    required: true
  ],
  tags: [
    type: :string,
    multiple: true,
    long: "tag",
    doc: "Tags to consider"
  ],
  verbose: [
    type: :boolean,
    doc: "Enable verbose logging",
  ],
  timeout: [
    type: :integer,
    doc: "The timeout in seconds",
    default: 10
  ]
]
```

Now you can validate some `argv` using `CliOptions.parse/2`.

```elixir
iex> CliOptions.parse(["-p", "foo", "--timeout", "30"], schema, as_tuple: true)
{:ok, {[project: "foo", verbose: false, timeout: 30], [], []}}
```

If the input arguments are valid a tuple of the form `{options, args, extra}` is
returned. Check the `CliOptions` docs for more details.

If the input is invalid an error will be returned:

```elixir
# invalid type
iex> CliOptions.parse(["-p", "foo", "--timeout", "a30"], schema, as_tuple: true)
{:error, ":timeout expected an integer argument, got: a"}

# missing required argument
iex> CliOptions.parse([], schema, as_tuple: true)
{:error, "option :project is required"}

# with undefined argument
iex> CliOptions.parse(["-p", "foo", "--other", "x"], schema, as_tuple: true)
{:error, "invalid option other"}
```

### Auto-generated docs

`Cli.Options.docs/2` can be used to automatically generate documentation from a
valid schema. You can use it directly in the `@moduledoc` of your mix tasks as
following:

```elixir
defmoudle Mix.Tasks.SomeTask do
  schema = [...]

  @moduledoc """
  Some task.

  ## CLI Options

  #{CliOptions.docs(schema)}
  """
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cli_options` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cli_options, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/cli_options>.

## Acknowledgements

- The awesome [`clap`](https://docs.rs/clap/latest/clap/) Rust CLI parser.
- [`nimble_options`](https://github.com/dashbitco/nimble_options).
