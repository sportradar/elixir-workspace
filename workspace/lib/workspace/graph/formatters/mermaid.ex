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

    {app_ids, path_ids} = node_ids(graph)

    vertices =
      :digraph.vertices(graph)
      |> Enum.map(fn node -> "  #{vertex(node, app_ids, path_ids)}" end)
      |> Enum.sort()
      |> Enum.join("\n")

    external =
      :digraph.vertices(graph)
      |> Enum.filter(fn node -> node.type == :external end)
      |> Enum.map(&app_ids[&1.app])

    edges =
      :digraph.edges(graph)
      |> Enum.map(fn edge ->
        {_e, v1, v2, _l} = :digraph.edge(graph, edge)
        {v1, v2}
      end)
      |> Enum.map(fn {v1, v2} ->
        "  #{node_id(v1, app_ids, path_ids)} --> #{node_id(v2, app_ids, path_ids)}"
      end)
      |> Enum.sort()
      |> Enum.join("\n")

    """
    flowchart TD
    #{vertices}

    #{edges}
    #{external_node_format(external)}#{path_node_format(workspace, path_ids, show_status)}
    #{maybe_mermaid_node_format(workspace, app_ids, path_ids, show_status)}
    """
    |> String.trim()
  end

  # mermaid keywords cannot be used as node ids
  @reserved_ids ~w(end graph subgraph flowchart style class classDef click linkStyle direction)

  # projects are rendered with their app name as id, unless it is a reserved
  # keyword. Paths get generated ids, since their labels may contain arbitrary
  # characters. In both cases generated ids skip any id already used.
  defp node_ids(graph) do
    {path_nodes, project_nodes} =
      :digraph.vertices(graph)
      |> Enum.split_with(&Workspace.Graph.Node.path?/1)

    taken_ids = MapSet.new(project_nodes, &to_string(&1.app))

    {app_ids, taken_ids} =
      project_nodes
      |> Enum.sort_by(& &1.app)
      |> Enum.map_reduce(taken_ids, fn node, taken_ids ->
        app = to_string(node.app)

        id =
          if app in @reserved_ids,
            do: free_id(taken_ids, &"#{app}_project#{if &1 > 0, do: "_#{&1}"}"),
            else: app

        {{node.app, id}, MapSet.put(taken_ids, id)}
      end)

    path_ids =
      path_nodes
      |> Enum.sort_by(& &1.label)
      |> Enum.map_reduce(taken_ids, fn node, taken_ids ->
        id = free_id(taken_ids, &"path_#{&1}")
        {{node, id}, MapSet.put(taken_ids, id)}
      end)
      |> elem(0)

    {Map.new(app_ids), Map.new(path_ids)}
  end

  defp free_id(taken_ids, id_fun) do
    Stream.iterate(0, &(&1 + 1))
    |> Stream.map(id_fun)
    |> Enum.find(&(not MapSet.member?(taken_ids, &1)))
  end

  defp vertex(%Workspace.Graph.Node{type: :path} = node, _app_ids, path_ids),
    do: ~s(#{path_ids[node]}[/"#{String.replace(node.label, "\"", "#quot;")}"/])

  defp vertex(node, app_ids, _path_ids) do
    id = app_ids[node.app]

    if id == to_string(node.app), do: id, else: ~s(#{id}["#{node.app}"])
  end

  defp node_id(%Workspace.Graph.Node{type: :path} = node, _app_ids, path_ids),
    do: path_ids[node]

  defp node_id(node, app_ids, _path_ids), do: app_ids[node.app]

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

  defp maybe_mermaid_node_format(_workspace, _app_ids, _path_ids, false), do: ""

  defp maybe_mermaid_node_format(workspace, app_ids, path_ids, true) do
    path_styles =
      workspace
      |> changed_path_ids(path_ids, true)
      |> Enum.map(fn id -> "  class #{id} modified;" end)

    node_styles =
      Workspace.projects(workspace)
      |> Enum.filter(fn project -> project.status in [:modified, :affected] end)
      |> Enum.map(fn project ->
        "  class #{app_ids[project.app] || project.app} #{project.status};"
      end)
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
