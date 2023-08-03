defmodule Workspace.Utils.Path do
  @moduledoc """
  Helper `Path` utilities.
  """

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
end
