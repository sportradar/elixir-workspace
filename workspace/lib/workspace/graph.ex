defmodule Workspace.Graph do
  @moduledoc """
  Workspace path dependencies graph and helper utilities

  ## Internal representation of the graph

  Each graph node is a tuple of the form `{package_name, package_type}` where
  `package_type` is one of:

    * `:workspace` - for workspace internal projects
    * `:external` - for external projects / dependencies

  By default `:workspace` will always be included in the graph. On the other hand
  `:external` dependencies will be included only if the `:external` option is set
  to `true` during graph's construction.
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
    graph = digraph(workspace)

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
  """
  @spec digraph(workspace :: Workspace.t(), opts :: keyword()) :: :digraph.graph()
  def digraph(workspace, opts \\ []) do
    graph = :digraph.new()

    for {app, _project} <- workspace.projects do
      :digraph.add_vertex(graph, {app, :workspace})
    end

    for {_app, project} <- workspace.projects,
        {dep, dep_config} <- project.config[:deps] || [],
        # TODO fixup create a workspace_project? instead and use it
        path_dependency?(dep_config) do
      :digraph.add_edge(graph, {project.app, :workspace}, {dep, :workspace})
    end

    graph
  end

  defp path_dependency?(config) when is_binary(config), do: false
  defp path_dependency?(config), do: config[:path] != nil

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
      |> Enum.map(fn {app, _type} -> app end)
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
      |> Enum.map(fn {app, _type} -> app end)
    end)
  end

  @doc """
  Get the affected workspace's projects given the changed projects

  Notice that the project names are returned, you can use `Workspace.project/2`
  to map them back into projects.
  """
  @spec affected(workspace :: Workspace.t(), projects :: [atom()]) :: [atom()]
  def affected(workspace, projects) do
    projects = Enum.map(projects, fn project -> {project, :workspace} end)

    with_digraph(workspace, fn graph ->
      :digraph_utils.reaching_neighbours(projects, graph)
      |> Enum.concat(projects)
      |> Enum.uniq()
      |> Enum.map(fn {app, _type} -> app end)
    end)
  end
end
