defmodule Workspace.State do
  @moduledoc """
  The low-level API and the workspace state struct.

  ## The `%Workspace.State{}` structure

  Every workspace is stored internally as a struct containing the following
  fields:

    * `:projects` - a map of the form `%{atom => Workspace.Project.t()}` where
    the key is the defined project name. It includes all detected workspace
    projects excluding any ignored ones.
    * `:cwd` - the directory from which the generation of the workspace struct
    occurred.
    * `:mix_path` - absolute path to the workspace's root `mix.exs` file.
    * `:workspace_path` - absolute path of the workspace, this is by default the
    folder containing the workspace mix file.
    * `:git_root_path` - the absolute path of the git repository containing the
    workspace
    * `:config` - the workspace's configuration, check `Workspace.Config` for
    more details.

  """

  @typedoc """
  Struct holding the workspace state.

  It contains the following:

  * `:projects` - A map with all workspace projects.
  * `:config` - The workspace configuration settings.
  * `:mix_path` - The path to the workspace's root `mix.exs`.
  * `:workspace_path` - The workspace root path.
  * `:git_root_path` - The git root path, of the repository containing the workspace.
  * `:cwd` - The directory from which the workspace was generated.
  * `:graph` - The DAG (directed acyclic graph) of the workspace.
  * `:status_updated?` - Set to `true` if the workspace status has been updated.
  """
  @type t :: %Workspace.State{
          projects: %{atom() => Workspace.Project.t()},
          config: keyword(),
          mix_path: binary(),
          workspace_path: binary(),
          git_root_path: binary() | nil,
          cwd: binary(),
          graph: :digraph.graph(),
          status_updated?: boolean()
        }

  @enforce_keys [:config, :mix_path, :workspace_path, :cwd]
  defstruct projects: %{},
            config: nil,
            mix_path: nil,
            workspace_path: nil,
            cwd: nil,
            git_root_path: nil,
            graph: nil,
            status_updated?: false

  @doc """
  Initializes a new workspace from the given settings.

  It expects the following:

  - `path` is the root path of the workspace
  - `mix_path` is the root mix file, usually a `mix.exs` in the `path`
  - `config` is the workspace configuration
  - `projects` is a list of workspace projects

  Notice that *no validation is applied* at this level.
  """
  @spec new(
          path :: String.t(),
          mix_path :: String.t(),
          config :: keyword(),
          projects :: [Workspace.Project.t()]
        ) :: t()
  def new(path, mix_path, config, projects) do
    git_root_path = git_root_path(path)
    graph = Workspace.Graph.digraph(projects)
    projects = update_projects_topology(projects, graph)

    %__MODULE__{
      config: config,
      mix_path: mix_path,
      workspace_path: path,
      cwd: File.cwd!(),
      graph: graph,
      git_root_path: git_root_path
    }
    |> set_projects(projects)
  end

  defp git_root_path(path) do
    if File.exists?(path) do
      case Workspace.Git.root(cd: path) do
        {:error, _reason} -> nil
        {:ok, path} -> path
      end
    else
      # this is mostly for tests where we use artificial non existing directories
      nil
    end
  end

  defp update_projects_topology(projects, graph) do
    roots = Workspace.Graph.source_projects(graph)

    Enum.map(projects, fn project ->
      Workspace.Project.set_root(project, project.app in roots)
    end)
  end

  @doc false
  @spec set_projects(workspace :: t(), projects :: [Workspace.Project.t()] | map()) :: t()
  def set_projects(workspace, projects) when is_list(projects) do
    projects =
      projects
      |> Enum.map(fn project -> {project.app, project} end)
      |> Enum.into(%{})

    set_projects(workspace, projects)
  end

  def set_projects(workspace, projects) when is_map(projects) do
    %__MODULE__{workspace | projects: projects}
  end

  @doc false
  @spec status_updated(workspace :: t()) :: t()
  def status_updated(workspace), do: %__MODULE__{workspace | status_updated?: true}

  @doc false
  @spec status_updated?(workspace :: t()) :: boolean()
  def status_updated?(workspace), do: workspace.status_updated?
end
