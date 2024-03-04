defmodule CliOptions.Options do
  @moduledoc """
  The struct holding the parsed CLI options.

  It contains the following fields:

  * `argv` - the input argv string list
  * `schema` - the schema used for validation
  * `opts` - the extracted command line options
  * `args` - a list of the remaining arguments in `argv` as strings
  * `extra` - a list of unparsed arguments, if applicable.
  """

  @type argv :: [String.t()]

  @type t :: %__MODULE__{
          argv: argv(),
          schema: keyword(),
          opts: keyword(),
          args: argv(),
          extra: nil | argv()
        }

  @enforce_keys [:argv, :schema, :opts, :args, :extra]
  defstruct argv: nil,
            schema: nil,
            opts: nil,
            args: [],
            extra: nil

  @spec new(
          argv :: argv(),
          schema :: keyword(),
          opts :: keyword(),
          args :: argv(),
          extra :: nil | argv()
        ) :: t()
  def new(argv, schema, opts, args, extra) do
    %__MODULE__{argv: argv, schema: schema, opts: opts, args: args, extra: extra}
  end
end
