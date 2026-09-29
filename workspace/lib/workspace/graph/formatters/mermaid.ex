defmodule Workspace.Graph.Formatters.Mermaid do
  @moduledoc false

  @behaviour Workspace.Graph.Formatter

  @impl true
  def render(graph, workspace, opts) do
    to_mermaid(graph, workspace, opts)
    |> IO.puts()
  end

  @doc false
  @spec to_mermaid(graph :: :digraph.graph(), workspace :: Workspace.State.t(), opts :: keyword()) ::
          String.t()
  def to_mermaid(graph, workspace, opts) do
    show_status = opts[:show_status] || false

    # mermaid ids cannot contain arbitrary characters, so paths get generated
    # ids, sorted by label for deterministic output, skipping any id that is
    # already used by a project
    taken_ids =
      :digraph.vertices(graph)
      |> Enum.reject(&Workspace.Graph.Node.path?/1)
      |> MapSet.new(&to_string(&1.app))

    path_nodes =
      :digraph.vertices(graph)
      |> Enum.filter(&Workspace.Graph.Node.path?/1)
      |> Enum.sort_by(& &1.label)

    path_ids =
      Stream.iterate(0, &(&1 + 1))
      |> Stream.map(&"path_#{&1}")
      |> Stream.reject(&MapSet.member?(taken_ids, &1))
      |> Enum.zip(path_nodes)
      |> Map.new(fn {id, node} -> {node, id} end)

    vertices =
      :digraph.vertices(graph)
      |> Enum.map(fn node -> "  #{vertex(node, path_ids)}" end)
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
      |> Enum.map(fn {v1, v2} -> "  #{node_id(v1, path_ids)} --> #{node_id(v2, path_ids)}" end)
      |> Enum.sort()
      |> Enum.join("\n")

    """
    flowchart TD
    #{vertices}

    #{edges}
    #{external_node_format(external)}#{path_node_format(workspace, path_ids, show_status)}
    #{maybe_mermaid_node_format(workspace, path_ids, show_status)}
    """
    |> String.trim()
  end

  defp vertex(%Workspace.Graph.Node{type: :path} = node, path_ids),
    do: ~s(#{path_ids[node]}[/"#{String.replace(node.label, "\"", "#quot;")}"/])

  defp vertex(node, _path_ids), do: node.app

  defp node_id(%Workspace.Graph.Node{type: :path} = node, path_ids), do: path_ids[node]
  defp node_id(node, _path_ids), do: node.app

  # changed paths are styled as modified if the status is shown
  defp path_node_format(_workspace, path_ids, _show_status) when path_ids == %{}, do: ""

  defp path_node_format(workspace, path_ids, show_status) do
    changed = changed_path_ids(workspace, path_ids, show_status)

    path_styles =
      path_ids
      |> Map.values()
      |> Enum.reject(&(&1 in changed))
      |> Enum.sort()
      |> Enum.map_join("", fn id -> "\n  class #{id} path;" end)

    path_styles <> "\n  classDef path fill:#eee,color:#333;"
  end

  defp changed_path_ids(_workspace, _path_ids, false), do: []

  defp changed_path_ids(workspace, path_ids, true) do
    changed_paths = Workspace.Status.changed_paths(workspace)

    for {node, id} <- path_ids, node.path in changed_paths, do: id
  end

  defp external_node_format(external) do
    external_styles = Enum.map_join(external, "\n", fn app -> "  class #{app} external;" end)

    [external_styles, "  classDef external fill:#999,color:#ee0;"]
    |> Enum.join("\n")
  end

  defp maybe_mermaid_node_format(_workspace, _path_ids, false), do: ""

  defp maybe_mermaid_node_format(workspace, path_ids, true) do
    path_styles =
      workspace
      |> changed_path_ids(path_ids, true)
      |> Enum.map(fn id -> "  class #{id} modified;" end)

    node_styles =
      Workspace.projects(workspace)
      |> Enum.filter(fn project -> project.status in [:modified, :affected] end)
      |> Enum.map(fn project -> "  class #{project.app} #{project.status};" end)
      |> Enum.concat(path_styles)
      |> Enum.sort()
      |> Enum.join("\n")

    """

    #{node_styles}

      classDef affected fill:#FA6,color:#FFF;
      classDef modified fill:#F33,color:#FFF;
    """
  end
end
