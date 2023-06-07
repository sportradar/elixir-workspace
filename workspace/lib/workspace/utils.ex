defmodule Workspace.Utils do
  @moduledoc false

  @doc false
  # TODO: Remove once we upgrade to elixir 1.16.0
  def relative_path_to(path, cwd) do
    split_path = path |> Path.expand() |> Path.split()
    split_cwd = cwd |> Path.expand() |> Path.split()

    relative_path_to(split_path, split_cwd, split_path)
  end

  defp relative_path_to(path, path, _original), do: "."
  defp relative_path_to([h | t1], [h | t2], original), do: relative_path_to(t1, t2, original)

  # this should only happen if we have two paths on different drives on windows
  defp relative_path_to(original, _, original), do: Path.join(original)

  defp relative_path_to(l1, l2, _original) do
    base = List.duplicate("..", length(l2))
    Path.join(base ++ l1)
  end
end
