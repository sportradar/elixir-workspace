defmodule Cascade.Checks do
  @moduledoc """
  Useful generic checks for templates.
  """

  @doc """
  Ensure that the given `name` is a valid module name.
  """
  @spec check_module_name_validity!(name :: String.t()) :: :ok
  def check_module_name_validity!(name) do
    unless name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/ do
      raise ArgumentError,
            "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
    end

    :ok
  end

  @doc """
  Ensure that the given module name is available.
  """
  @spec check_module_name_availability!(name :: String.t()) :: :ok
  def check_module_name_availability!(name) do
    name = Module.concat(Elixir, name)

    if Code.ensure_loaded?(name) do
      raise ArgumentError,
            "Module name #{inspect(name)} is already taken, please choose another name"
    end

    :ok
  end

  @doc """
  Ensure that the given directory exists
  """
  @spec check_directory_existence!(name :: String.t()) :: :ok
  def check_directory_existence!(path) do
    if File.dir?(path) do
      raise ArgumentError, "Directory #{path} exists already."
    end

    :ok
  end
end
