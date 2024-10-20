defmodule Cascade.Utils do
  @moduledoc false

  @doc false
  @spec modules_implementing_behaviour(behaviour :: module()) :: [module()]
  def modules_implementing_behaviour(behaviour) do
    modules =
      Enum.map(:code.all_available(), fn {module, _path, _loaded} ->
        String.to_atom(to_string(module))
      end)

    for module <- modules,
        Code.ensure_loaded?(module),
        behaviour in (module.module_info(:attributes)[:behaviour] || []) do
      module
    end
  end

  @doc false
  @spec implements_behaviour?(module :: module(), behaviour :: module()) :: boolean()
  def implements_behaviour?(module, behaviour) do
    Code.ensure_loaded!(module)
    behaviours = module.module_info()[:attributes][:behaviour]

    case behaviours do
      nil -> false
      behaviours -> Enum.member?(behaviours, behaviour)
    end
  end

  @doc """
  Returns `true` if the given `path` is relative, `false` otherwise.

  ## Examples

      iex> Workspace.Utils.Path.relative?("../local")
      true

      iex> Workspace.Utils.Path.relative?("./path/to/cli.ex")
      true

      iex> Workspace.Utils.Path.relative?("/usr/local/cli.ex")
      false
  """
  @spec relative?(path :: Path.t()) :: boolean()
  def relative?(path), do: Path.type(path) == :relative
end
