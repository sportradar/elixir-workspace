defmodule Workspace.Graph.Formatters.Mermaid do
  @moduledoc false

  @behaviour Workspace.Graph.Formatter

  @impl true
  def render(workspace, opts) do
    Workspace.Graph.with_digraph(
      workspace,
      fn graph ->
        vertices =
          :digraph.vertices(graph)
          |> Enum.map(fn node -> "  #{node.app}" end)
          |> Enum.sort()
          |> Enum.join("\n")

        external =
          :digraph.vertices(graph)
          |> Enum.filter(fn node -> node.type == :external end)
          |> Enum.map(& &1.app)

        edges =
          :digraph.edges(graph)
          |> Enum.map(fn edge ->
            {_e, v1, v2, _l} = :digraph.edge(graph, edge)
            {v1, v2}
          end)
          |> Enum.map(fn {v1, v2} -> "  #{v1.app} --> #{v2.app}" end)
          |> Enum.sort()
          |> Enum.join("\n")

        """
        flowchart TD
        #{vertices}

        #{edges}
        #{external_node_format(external)}
        #{maybe_mermaid_node_format(workspace, opts[:show_status])}
        """
        |> String.trim()
        |> IO.puts()
      end,
      external: opts[:external],
      ignore: opts[:ignore]
    )
  end

  defp external_node_format(external) do
    external_styles = Enum.map_join(external, "\n", fn app -> "  class #{app} external;" end)

    [external_styles, "  classDef external fill:#999,color:#ee0;"]
    |> Enum.join("\n")
  end

  defp maybe_mermaid_node_format(_worksapce, false), do: ""

  defp maybe_mermaid_node_format(workspace, true) do
    node_styles =
      Workspace.projects(workspace)
      |> Enum.filter(fn project -> project.status in [:modified, :affected] end)
      |> Enum.map_join("\n", fn project -> "  class #{project.app} #{project.status};" end)

    """

    #{node_styles}

      classDef affected fill:#FA6,color:#FFF;
      classDef modified fill:#F33,color:#FFF;
    """
  end
end