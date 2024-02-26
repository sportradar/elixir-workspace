defmodule Workspace.Graph do
  @moduledoc """
  Workspace path dependencies graph and helper utilities

  ## Internal representation of the graph

  Each graph node is a tuple of the form `{package_name, package_type}` where
  `package_type` is one of:

    * `:workspace` - for workspace internal projects
    * `:external` - for external projects / dependencies

  By default `:workspace` dependencies will always be included in the graph. On the
  other hand `:external` dependencies will be included only if the `:external`
  option is set to `true` during graph's construction.
  """

  @type vertices :: [:digraph.vertex()]

  @doc """
  Runs the given `callback` on the workspace's graph

  `callback` should be a function expecting as input a `:digraph.graph()`. For
  supported options check `digraph/2`
  """
  @spec with_digraph(
          workspace :: Workspace.State.t(),
          callback :: (:digraph.graph() -> result),
          opts :: keyword()
        ) ::
          result
        when result: term()
  def with_digraph(workspace, callback, opts \\ []) do
    graph = digraph(workspace, opts)

    try do
      callback.(graph)
    after
      :digraph.delete(graph)
    end
  end

  @doc """
  Generates a graph of the given workspace.

  Notice that you need to manually delete the graph. Prefer instead
  `with_digraph/2`.

  ## Options

    * `:external` - if set external dependencies will be included as well
    * `:exclude` - if set the specified workspace projects will not be included
    in the graph
  """
  @spec digraph(
          workspace_or_projects :: Workspace.State.t() | [Workspace.Project.t()],
          opts :: keyword()
        ) :: :digraph.graph()
  def digraph(workspace_or_projects, opts \\ [])

  def digraph(workspace, opts) when is_struct(workspace, Workspace.State) do
    digraph(Map.values(workspace.projects), opts)
  end

  def digraph(projects, opts) when is_list(projects) do
    Workspace.Cli.debug("generating workspace graph")

    excluded =
      Keyword.get(opts, :exclude, [])
      |> Enum.map(&maybe_to_atom/1)

    graph_nodes = valid_nodes(projects, opts[:external], excluded)
    graph_apps = Enum.map(graph_nodes, fn node -> elem(node, 0) end)

    graph = :digraph.new()

    # add vertices
    for {app, type} <- graph_nodes do
      node = graph_node(app, type)
      :digraph.add_vertex(graph, node)
    end

    for project <- projects,
        dep <- project_deps(project),
        project.app in graph_apps,
        dep in graph_apps do
      from_node = node_by_app(graph, project.app)
      to_node = node_by_app(graph, dep)
      :digraph.add_edge(graph, from_node, to_node)
    end

    graph
  end

  defp maybe_to_atom(item) when is_atom(item), do: item
  defp maybe_to_atom(item) when is_binary(item), do: String.to_atom(item)

  defp valid_nodes(projects, external, excluded) do
    workspace_nodes =
      for project <- projects,
          app = project.app,
          not excluded_app?(app, excluded) do
        {app, :workspace}
      end

    workspace_nodes ++ maybe_external_dependencies(projects, external, excluded)
  end

  defp project_deps(project) do
    deps = project.config[:deps] || []

    Enum.map(deps, fn dep -> elem(dep, 0) end)
  end

  defp maybe_external_dependencies(projects, true, excluded) do
    workspace_apps = Enum.map(projects, & &1.app)

    projects
    |> Enum.reject(fn project -> excluded_app?(project.app, excluded) end)
    |> Enum.map(fn project -> project.config[:deps] || [] end)
    |> List.flatten()
    |> Enum.map(fn dep -> elem(dep, 0) end)
    |> Enum.uniq()
    |> Enum.reject(fn dep -> dep in workspace_apps or excluded_app?(dep, excluded) end)
    |> Enum.map(fn dep -> {dep, :external} end)
  end

  defp maybe_external_dependencies(_workspace, _external, _excluded), do: []

  defp graph_node(app, :workspace),
    do: Workspace.Graph.Node.new(app, :workspace)

  defp graph_node(app, :external), do: Workspace.Graph.Node.new(app, :external)

  defp excluded_app?(app, excluded) when is_atom(app), do: app in excluded

  @doc """
  Return the source projects of the workspace

  The input can be either a `Workspace` struct or the workspace graph. In case of a
  `Workspace` a temporary graph will be constructed.

  Notice that the project names are returned, you can use `Workspace.project/2`
  to map them back into projects.
  """
  @spec source_projects(workspace :: Workspace.State.t() | :digraph.graph()) :: [atom()]
  def source_projects(workspace) when is_struct(workspace, Workspace.State) do
    with_digraph(workspace, fn graph ->
      source_projects(graph)
    end)
  end

  def source_projects(graph) do
    graph
    |> :digraph.source_vertices()
    |> Enum.map(& &1.app)
  end

  @doc """
  Return the sink projects of the workspace

  Notice that the project names are returned, you can use `Workspace.project/2`
  to map them back into projects.
  """
  @spec sink_projects(workspace :: Workspace.State.t()) :: [atom()]
  def sink_projects(workspace) do
    with_digraph(workspace, fn graph ->
      graph
      |> :digraph.sink_vertices()
      |> Enum.map(& &1.app)
    end)
  end

  @doc """
  Get the affected workspace's projects given the changed `projects`

  Notice that the project names are returned, you can use `Workspace.project/2`
  to map them back into projects.
  """
  @spec affected(workspace :: Workspace.State.t(), projects :: [atom()]) :: [atom()]
  def affected(workspace, projects) do
    with_digraph(workspace, fn graph ->
      nodes = Enum.map(projects, fn project -> node_by_app(graph, project) end)

      :digraph_utils.reaching_neighbours(nodes, graph)
      |> Enum.map(& &1.app)
      |> Enum.concat(projects)
      |> Enum.uniq()
    end)
  end

  defp node_by_app(graph, app) do
    Enum.find(:digraph.vertices(graph), &(&1.app == app))
  end

  @doc """
  Returns the direct dependencies of the given `project`

  The direct dependencies are the path dependencies that are defined in the
  `project`' s `mix.exs`.
  """
  @spec dependencies(workspace :: Workspace.State.t(), project :: atom()) :: [atom()]
  def dependencies(workspace, project) do
    node = node_by_app(workspace.graph, project)

    :digraph.out_neighbours(workspace.graph, node)
    |> Enum.map(& &1.app)
  end

  @doc """
  Returns a subgraph around the given `project` and all nodes within the given `proximity`.
  """
  @spec subgraph(
          graph :: :digraph.graph(),
          project :: Workspace.Project.t(),
          proximity :: pos_integer()
        ) :: :digraph.graph()
  def subgraph(graph, project, proximity) do
    node = node_by_app(graph, project)

    vertices =
      :digraph.vertices(graph)
      |> Enum.filter(fn vertex -> within_proximity?(graph, vertex, node, proximity) end)
      |> Enum.concat([node])

    :digraph_utils.subgraph(graph, vertices)
  end

  defp within_proximity?(graph, vertex1, vertex2, proximity) do
    shortest_path =
      :digraph.get_short_path(graph, vertex1, vertex2) ||
        :digraph.get_short_path(graph, vertex2, vertex1)

    case shortest_path do
      false -> false
      path -> Enum.count(path) <= proximity + 1
    end
  end
end
