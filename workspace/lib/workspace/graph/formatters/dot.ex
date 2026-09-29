defmodule Workspace.Graph.Formatters.Dot do
  @moduledoc false

  @behaviour Workspace.Graph.Formatter

  @impl true
  def render(graph, _workspace, _opts) do
    paths =
      :digraph.vertices(graph)
      |> Enum.filter(&Workspace.Graph.Node.path?/1)
      |> Enum.map(&"  #{node_id(&1)} [shape=folder];")
      |> Enum.sort()

    # projects without any edge must be declared explicitly, otherwise they
    # are not included in the graph
    isolated =
      :digraph.vertices(graph)
      |> Enum.filter(&(:digraph.in_degree(graph, &1) + :digraph.out_degree(graph, &1) == 0))
      |> Enum.map(&"  #{node_id(&1)};")
      |> Enum.sort()

    edges =
      :digraph.edges(graph)
      |> Enum.map(fn edge ->
        {_e, v1, v2, _l} = :digraph.edge(graph, edge)
        "  #{node_id(v1)} -> #{node_id(v2)};"
      end)
      |> Enum.sort()

    """
    digraph G {
    #{Enum.join(paths ++ isolated ++ edges, "\n")}
    }
    """
    |> String.trim()
    |> IO.puts()
  end

  # ids are always quoted, since project names may be DOT keywords, e.g. graph
  defp node_id(%Workspace.Graph.Node{type: :path, label: label}), do: quote_id(label)
  defp node_id(node), do: quote_id(to_string(node.app))

  defp quote_id(id), do: ~s("#{String.replace(id, "\"", "\\\"")}")
end
