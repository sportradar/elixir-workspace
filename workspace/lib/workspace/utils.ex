defmodule Workspace.Utils do
  @moduledoc false

  @doc false
  @spec keyword_take!(keywords :: keyword(), keys :: [atom()]) :: keyword()
  def keyword_take!(keywords, keys) when is_list(keywords) and is_list(keys) do
    {take, missing} =
      Enum.reduce(keys, {[], []}, fn key, {take, missing} ->
        case Keyword.has_key?(keywords, key) do
          true -> {[{key, keywords[key]} | take], missing}
          false -> {take, [key | missing]}
        end
      end)

    if missing != [] do
      raise KeyError, key: missing, term: keywords
    end

    take
  end

  # TODO: Remove once we upgrade to elixir 1.16.0
  @doc false
  @spec relative_path_to(path :: binary(), cwd :: binary()) :: binary()
  def relative_path_to(path, cwd) do
    cond do
      relative?(path) ->
        path

      true ->
        split_path = path |> Path.expand() |> Path.split()
        split_cwd = cwd |> Path.expand() |> Path.split()

        relative_path_to(split_path, split_cwd, split_path)
    end
  end

  defp relative_path_to(path, path, _original), do: "."
  defp relative_path_to([h | t1], [h | t2], original), do: relative_path_to(t1, t2, original)

  defp relative_path_to(l1, l2, _original) do
    base = List.duplicate("..", length(l2))
    Path.join(base ++ l1)
  end

  defp relative?(path), do: Path.type(path) == :relative

  @doc false
  @spec digraph_to_mermaid(graph :: :digraph.graph()) :: binary()
  def digraph_to_mermaid(graph) do
    vertices =
      :digraph.vertices(graph)
      |> Enum.map(fn v -> "  #{v}" end)
      |> Enum.sort()
      |> Enum.join("\n")

    edges =
      :digraph.edges(graph)
      |> Enum.map(fn edge ->
        {_e, v1, v2, _l} = :digraph.edge(graph, edge)
        {v1, v2}
      end)
      |> Enum.map(fn {v1, v2} -> "  #{v1} --> #{v2}" end)
      |> Enum.sort()
      |> Enum.join("\n")

    """
    flowchart TD
    #{vertices}

    #{edges}
    """
    |> String.trim()
  end
end
