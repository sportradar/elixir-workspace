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
