defmodule Cascade.Checks do
  @moduledoc """
  Useful generic checks for templates.
  """

  def check_module_name_validity!(name) do
    unless name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/ do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  def check_module_name_availability!(name) do
    name = Module.concat(Elixir, name)

    if Code.ensure_loaded?(name) do
      Mix.raise("Module name #{inspect(name)} is already taken, please choose another name")
    end
  end

  def check_directory_existence!(path) do
    if File.dir?(path) do
      Mix.raise("Directory #{path} exists")
    end
  end
end
