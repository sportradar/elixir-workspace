defmodule Workspace.Graph.Formatters.Dot do
  @moduledoc false

  @behaviour Workspace.Graph.Formatter

  @impl true
  def render(graph, _workspace, _opts) do
    edges =
      :digraph.edges(graph)
      |> Enum.map(fn edge ->
        {_e, v1, v2, _l} = :digraph.edge(graph, edge)
        {v1, v2}
      end)
      |> Enum.sort()
      |> Enum.map(fn {v1, v2} -> "  #{v1.app} -> #{v2.app};" end)
      |> Enum.join("\n")

    """
    digraph G {
    #{edges}
    }
    """
    |> String.trim()
    |> IO.puts()
  end
end
