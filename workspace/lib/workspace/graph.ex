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
          workspace :: Workspace.t(),
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
    * `:ignore` - if set the specified workspace projects will not be included
    in the graph
  """
  @spec digraph(workspace :: Workspace.t(), opts :: keyword()) :: :digraph.graph()
  def digraph(workspace, opts \\ []) do
    graph_nodes = valid_nodes(workspace, opts[:external], opts[:ignore])
    graph_apps = Enum.map(graph_nodes, fn node -> elem(node, 0) end)

    graph = :digraph.new()

    # add vertices
    for {app, type, project} <- graph_nodes do
      node = graph_node(app, type, project)
      :digraph.add_vertex(graph, node)
    end

    for {_app, project} <- workspace.projects,
        dep <- project_deps(project),
        project.app in graph_apps,
        dep in graph_apps do
      from_node = node_by_app(graph, project.app)
      to_node = node_by_app(graph, dep)
      :digraph.add_edge(graph, from_node, to_node)
    end

    graph
  end

  defp valid_nodes(workspace, external, ignored) do
    workspace_nodes =
      for {app, project} <- workspace.projects,
          not ignored_app?(app, ignored) do
        {app, :workspace, project}
      end

    workspace_nodes ++ maybe_external_dependencies(workspace, external, ignored)
  end

  defp project_deps(project) do
    deps = project.config[:deps] || []

    Enum.map(deps, fn dep -> elem(dep, 0) end)
  end

  defp maybe_external_dependencies(workspace, true, ignored) do
    workspace_apps = Map.keys(workspace.projects)

    workspace.projects
    |> Enum.reject(fn {app, _project} -> ignored_app?(app, ignored) end)
    |> Enum.map(fn {_app, project} -> project.config[:deps] || [] end)
    |> List.flatten()
    |> Enum.map(fn dep -> elem(dep, 0) end)
    |> Enum.uniq()
    |> Enum.reject(fn dep -> dep in workspace_apps or ignored_app?(dep, ignored) end)
    |> Enum.map(fn dep -> {dep, :external, nil} end)
  end

  defp maybe_external_dependencies(_workspace, _external, _ignored), do: []

  defp graph_node(app, :workspace, project),
    do: Workspace.Graph.Node.new(app, :workspace, project: project)

  defp graph_node(app, :external, _project), do: Workspace.Graph.Node.new(app, :external)

  # TODO: make ignored list of atoms by default
  defp ignored_app?(_app, nil), do: false

  defp ignored_app?(app, ignored) when is_atom(app),
    do: ignored_app?(Atom.to_string(app), ignored)

  defp ignored_app?(app, ignored) when is_list(ignored), do: app in ignored

  @doc """
  Return the source projects of the workspace

  Notice that the project names are returned, you can use `Workspace.project/2`
  to map them back into projects.
  """
  @spec source_projects(workspace :: Workspace.t()) :: [atom()]
  def source_projects(workspace) do
    with_digraph(workspace, fn graph ->
      graph
      |> :digraph.source_vertices()
      |> Enum.map(& &1.app)
    end)
  end

  @doc """
  Return the sink projects of the workspace

  Notice that the project names are returned, you can use `Workspace.project/2`
  to map them back into projects.
  """
  @spec sink_projects(workspace :: Workspace.t()) :: [atom()]
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
  @spec affected(workspace :: Workspace.t(), projects :: [atom()]) :: [atom()]
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
end
