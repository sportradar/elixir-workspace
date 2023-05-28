defmodule Workspace.Graph do
  @moduledoc """
  Workspace path dependencies graph and helper utilities
  """

  def with_digraph(projects, callback) do
    graph = :digraph.new()

    try do
      for project <- projects do
        :digraph.add_vertex(graph, project[:app])
      end

      for project <- projects,
          {dep, dep_config} <- project[:config][:deps],
          path_dependency?(dep_config) do
        :digraph.add_edge(graph, project[:app], dep)
      end

      callback.(graph)
    after
      :digraph.delete(graph)
    end
  end

  defp path_dependency?(config) when is_binary(config), do: false
  defp path_dependency?(config), do: config[:path] != nil

  def source_projects do
    with_digraph(Workspace.projects(), fn graph -> :digraph.source_vertices(graph) end)
  end

  def sink_projects do
    with_digraph(Workspace.projects(), fn graph -> :digraph.sink_vertices(graph) end)
  end

  def affected(projects) do
    with_digraph(Workspace.projects(), fn graph ->
      :digraph_utils.reaching_neighbours(projects, graph)
      |> Enum.concat(projects)
      |> Enum.uniq()
    end)
  end

  def print_tree(projects) do
    with_digraph(projects, fn graph ->
      callback = fn {node, _format} ->
        children =
          :digraph.out_neighbours(graph, node)
          |> Enum.map(fn node -> {node, nil} end)
          |> Enum.sort()

        {{Atom.to_string(node), nil}, children}
      end

      root_nodes =
        graph
        |> :digraph.source_vertices()
        |> Enum.map(fn node -> {node, nil} end)
        |> Enum.sort()

      Mix.Utils.print_tree(root_nodes, callback)
    end)
  end
end
