defmodule CliOptions.Options do
  @moduledoc """
  The struct holding the parsed CLI options.
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
