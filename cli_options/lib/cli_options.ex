defmodule CliOptions do
  @moduledoc """
  Documentation for `CliOptions`.
  """

  def parse(argv, schema), do: CliOptions.Parser.parse(argv, schema)
end
