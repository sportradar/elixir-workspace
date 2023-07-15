defmodule PackageC do
  @moduledoc """
  Documentation for `PackageC`.
  """

  def hello, do: :world

  def hello(:foo), do: :bar
  def hello(:bar), do: :foo
  def hello(name), do: name
end
