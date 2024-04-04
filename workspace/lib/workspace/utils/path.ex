defmodule Workspace.Utils.Path do
  @moduledoc false

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
