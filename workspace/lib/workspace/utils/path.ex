defmodule Workspace.Utils.Path do
  @moduledoc false

  @doc """
  Checks if `base` is a parent directory of `path`

  Both paths are expanded before returning the relative path.

  ## Examples

      iex> Workspace.Utils.Path.parent_dir?("/usr/local", "/usr/local/foo/tmp")
      true

      iex> Workspace.Utils.Path.parent_dir?("/usr/local_foo", "/usr/local/foo/tmp")
      false
  """
  @spec parent_dir?(base :: Path.t(), path :: Path.t()) :: boolean()
  def parent_dir?(base, path) do
    base =
      base
      |> Path.expand()
      |> Path.split()

    path =
      path
      |> Path.expand()
      |> Path.split()

    starts_with?(path, base)
  end

  defp starts_with?(_path, []), do: true

  defp starts_with?([head | path_tail], [head | base_tail]),
    do: starts_with?(path_tail, base_tail)

  defp starts_with?(_path, _tail), do: false
end
