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
        behaviour in (module.module_info(:attributes)[:behaviour] || []) do
      module
    end
  end

  @doc false
  @spec implements_behaviour?(module :: module(), behaviour :: module()) :: boolean()
  def implements_behaviour?(module, behaviour) do
    Code.ensure_loaded!(module)
    behaviours = module.module_info[:attributes][:behaviour]

    case behaviours do
      nil -> false
      behaviours -> Enum.member?(behaviours, behaviour)
    end
  end

  # TODO: Remove once we upgrade to elixir 1.16.0
  @doc """
  Returns the relative path of `path` with respect to `cwd`

  Both paths are expanded before returning the relative path.
  """
  @spec relative_to(path :: binary(), cwd :: binary()) :: binary()
  def relative_to(path, cwd) do
    cond do
      relative?(path) ->
        path

      true ->
        split_path = path |> Path.expand() |> Path.split()
        split_cwd = cwd |> Path.expand() |> Path.split()

        relative_to(split_path, split_cwd, split_path)
    end
  end

  defp relative_to(path, path, _original), do: "."
  defp relative_to([h | t1], [h | t2], original), do: relative_to(t1, t2, original)

  defp relative_to(l1, l2, _original) do
    base = List.duplicate("..", length(l2))
    Path.join(base ++ l1)
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
