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

    edges =
      :digraph.edges(graph)
      |> Enum.map(fn edge ->
        {_e, v1, v2, _l} = :digraph.edge(graph, edge)
        "  #{node_id(v1)} -> #{node_id(v2)};"
      end)
      |> Enum.sort()

    """
    digraph G {
    #{Enum.join(paths ++ edges, "\n")}
    }
    """
    |> String.trim()
    |> IO.puts()
  end

  defp node_id(%Workspace.Graph.Node{type: :path, label: label}),
    do: ~s("#{String.replace(label, "\"", "\\\"")}")

  defp node_id(node), do: node.app
end
