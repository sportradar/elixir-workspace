defmodule CliOptions.ParseError do
  @moduledoc """
  An exception raised when parsing option fails.

  For example, see `CliOptions.parse!/2`.
  """

  defexception [:message]

  @impl Exception
  def exception(message) do
    %__MODULE__{message: message}
  end
end
