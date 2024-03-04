defmodule ParseError do
  @moduledoc """
  An exception raised when parsing option fails.

  For example, see `CliOptions.parse!/2`.
  """

  defexception [:message]
end
