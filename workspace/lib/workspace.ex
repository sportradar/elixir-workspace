defmodule Workspace do
  @moduledoc """
  A `Workspace` is a collection of mix projects under the same git repo.

  `Workspace` provides a set of tools for working with multiple projects under
  the same git repo. Using path dependencies between the projects and the
  provided tools you can effectively work on massive codebases properly
  splitted into reusable packages.

  ## The `%Workspace{}` structure

  Every workspace is stored internally as a struct containing the following
  fields:

  * `projects` - a map of the form `%{atom => Workspace.Project.t()}` where
  the key is the defined project name. It includes all detected workpsace
  projects excluding any ignored ones.
  * `cwd` - the directory from which the generation of the workspace struct
  occurred.
  * `mix_path` - absolute path to the workspace's root `mix.exs` file.
  * `workspace_path` - absolute path of the workspace, this is by default the
  folder containing the workspace mix file.
  * `config` - the workspace's config, check `Workspace.Config` and the
  following sections for more details.

  ## Workspace projects

  A mix project is considered a workspace project if:

  - it is located in a subfolder of the workspace root path
  - it is not included in the ignored projects or ignored paths in the
  workspace config

  Assuming the folder stucture:

  ```
  my_workspace
  ├── apps
  │   ├── api         # an API app 
  │   └── ui          # the UI project
  ├── mix.exs         # this is the workspace root definition
  ├── .workspace.exs  # the workspace config
  └── packages        # various reusable packages under packages
      ├── package_a 
      ├── package_b
      └── package_c
  ```

  - We have defined a `Workspace` under `my_workspace` folder
  - All mix projects under `my_workspace` are by default considered
  workspace packages. In the above example it will include the
  `:api`, `:ui`, `:package_a`, `:package_b` and `:package_c`
  packages.

  > #### Ignoring a package or a path {: .info}
  >
  > Assume you want to exclude `package_c` from the workspace. You
  > can add it to the `:ignore_projects` configuration option in
  > `.workspace.exs`:
  >
  > ```elixir
  > ignore_projects: [:package_a]
  > ```
  >
  > If you wanted to ignore all projects under an `other` folder
  > you could set the `:ignore_paths` option:
  >
  > ```elixir
  > ignore_paths: ["other"]
  > ```
  >
  > Notice that in the latter case the path is assumed to be relative to
  > the workspace root.
  >
  > For more details check the `Workspace.Config` documentation.

  > #### Duplicate package names {: .warning}
  >
  > Notice that duplicate package names are not allowed. If upon initialization
  > of a workspace two projects with the same `:name` are detected then
  > an exception will be raised.
  >
  > For example the following workspace:
  > 
  > ```
  > my_workspace
  > ├── apps
  > │   └── api
  > ├── mix.exs
  > ├── packages
  > │   ├── package_a  # package_a project defined under packages
  > │   └── package_b
  > └── shared
  >     └── package_a  # redefinition of package_a
  > ```
  >
  > would fail to initialize since `:package_a` is defined twice.

  ## Structuring a folder as a workspace root

  A workspace is a normal `Mix.Project` with some tweaks:

  - No actual code is expected, so `:elixirc_paths` is set to `[]`
  - It must have a `:workspace` project option set to `true`

  **TODO**: Once implemented add info about the generator

  ## Loading a workspace

  A `Workspace` can be constructed by calling the `new/2` function. It
  will use the given path and config object in order to load and validate
  all internal projects.

  ## The workspace graph

  The most important concept of the `Workspace` is the projects graph. The
  project graph must be a directed acyclic graph where each vertex is
  a project and each edge a dependency between the two projects.

  The workspace graph is constructed implicitely upon workspace's creation
  in order to ensure that all path dependencies are valid and decorate
  each project with graph metadata.

  > #### Inspecting the graph {: .tip}
  > 
  > You can use the `workspace.graph` command in order to see the
  > graph of the given `workspace`. For example:
  >
  > ```bash
  > mix workspace.graph --workspace-path test/fixtures/sample_workspace
  > ```
  >
  > on a test fixture would produce:
  >
  > ```
  > project_a
  > ├── project_b
  > │   └── project_g
  > ├── project_c
  > │   ├── project_e
  > │   └── project_f
  > │       └── project_g
  > └── project_d
  > project_h
  > └── project_d
  > project_i
  > └── project_j
  > project_k
  > ```
  >
  > You can additionally plot is as mermaid graph by specifying the
  > `--format mermaid` flag:
  >
  > ```mermaid
  > flowchart TD
  > project_a
  > project_b
  > project_c
  > project_d
  > project_e
  > project_f
  > project_g
  > project_h
  > project_i
  > project_j
  > project_k
  >
  > project_a --> project_b
  > project_a --> project_c
  > project_a --> project_d
  > project_b --> project_g
  > project_c --> project_e
  > project_c --> project_f
  > project_f --> project_g
  > project_h --> project_d
  > project_i --> project_j
  > ```
  """

  @type t :: %Workspace{
          projects: %{atom() => Workspace.Project.t()},
          config: keyword(),
          mix_path: binary(),
          workspace_path: binary(),
          cwd: binary()
        }

  @enforce_keys [:config, :mix_path, :workspace_path, :cwd]
  defstruct projects: %{},
            config: nil,
            mix_path: nil,
            workspace_path: nil,
            cwd: nil

  @doc """
  Creates a new `Workspace` from the given workspace path

  `config` can be one of the following:

  * A path relative to the workspace `path` with the workspace config
  * A loaded config object
  """
  @spec new(path :: binary(), config :: keyword() | binary()) :: t()
  def new(path, config \\ [])

  def new(path, config) when is_binary(config) do
    config_relative_path = Workspace.Utils.relative_path_to(config, Path.expand(path))

    config =
      Path.join(path, config_relative_path)
      |> Path.expand()
      |> config()

    new(path, config)
  end

  def new(path, config) when is_list(config) do
    # TODO refactor needed here
    {:ok, config} = Workspace.Config.validate(config)
    workspace_mix_path = Path.join(path, "mix.exs") |> Path.expand()
    workspace_path = Path.dirname(workspace_mix_path)

    ensure_workspace!(workspace_mix_path)

    projects = projects(workspace_path, config)

    %__MODULE__{
      config: config,
      mix_path: workspace_mix_path,
      workspace_path: workspace_path,
      cwd: File.cwd!()
    }
    |> set_projects(projects)
  end

  def set_projects(workspace, projects) when is_list(projects) do
    projects =
      projects
      |> Enum.map(fn project -> {project.app, project} end)
      |> Enum.into(%{})

    set_projects(workspace, projects)
  end

  def set_projects(workspace, projects) when is_map(projects) do
    %__MODULE__{workspace | projects: projects}
    |> update_projects_topology()
  end

  @doc """
  Get a list of the workspace projects
  """
  @spec projects(workspace :: Workspace.t()) :: [Workspace.Project.t()]
  def projects(workspace), do: Map.values(workspace.projects)

  @doc """
  Tries to load the workspace config from the given path

  If the config cannot be loaded or is not valid, the default config is
  returned.
  """
  @spec config(path :: binary()) :: keyword()
  def config(path) do
    case load_config_file(path) do
      {:ok, config} ->
        config

      {:error, reason} ->
        IO.warn("""
        Failed to load a valid workspace configuration from `#{path}`: #{reason}

        Using a default empty configuration. It is advised to create a `.workspace.exs`
        at the root of your workspace.
        """)

        []
    end
  end

  defp load_config_file(config_file) do
    config_file = Path.expand(config_file)

    case File.exists?(config_file) do
      false ->
        {:error, "file not found"}

      true ->
        {config, _bindings} = Code.eval_file(config_file)

        Workspace.Config.validate(config)
    end
  end

  defp ensure_workspace!(path) do
    if !workspace?(path) do
      Mix.raise("""
      Expected #{path} to be a workspace project. In order to define a project
      as workspace, you need to add the following to the project's config:

          workspace: true
      """)
    end
  end

  defp projects(workspace_path, config) do
    result =
      workspace_path
      |> nested_mix_projects(Keyword.fetch!(config, :ignore_paths), workspace_path)
      |> Enum.sort()
      |> Enum.map(fn path -> Workspace.Project.new(path, workspace_path) end)
      |> Enum.filter(&allowed_project?(&1, config))

    result
  end

  # TODO: add handling of nested workspaces
  defp nested_mix_projects(path, ignore_paths, workspace_path) do
    subdirs = subdirs(path, ignore_paths, workspace_path)

    projects = Enum.filter(subdirs, &mix_project?/1)
    remaining = subdirs -- projects

    Enum.reduce(remaining, projects, fn project, acc ->
      acc ++ nested_mix_projects(project, ignore_paths, workspace_path)
    end)
  end

  defp subdirs(path, ignore_paths, workspace_path) do
    path
    |> File.ls!()
    |> Enum.map(fn file -> Path.join(path, file) end)
    |> Enum.filter(fn path ->
      File.dir?(path) and not ignored_path?(path, ignore_paths, workspace_path)
    end)
  end

  defp mix_project?(path), do: File.exists?(Path.join(path, "mix.exs"))

  defp allowed_project?(project, config) do
    cond do
      project.module in config[:ignore_projects] ->
        false

      true ->
        true
    end
  end

  defp ignored_path?(mix_path, ignore_paths, workspace_path) do
    ignore_paths
    |> Enum.map(fn path -> workspace_path |> Path.join(path) |> Path.expand() end)
    |> Enum.any?(fn path -> String.starts_with?(mix_path, path) end)
  end

  @doc """
  Returns `true` if the given project is a workspace

  It expects one of the following:

  * a project config
  * a path to a `mix.exs` file
  * a path to a folder containing a root folder

  If a path is provided then the config of the project will be loaded first.

  If a path is provided then it will be expanded first.

  Raises if a path is provided which does not resolve to a valid `mix.exs`
  file.
  """
  @spec workspace?(config_or_path :: keyword() | binary()) :: boolean()
  def workspace?(path) when is_binary(path) do
    path =
      path
      |> Path.expand()
      |> mix_exs_path()

    if !File.exists?(path) do
      raise ArgumentError, """
      The input path is not a valid `mix.exs` file or a folder containing a
      mix project
      """
    end

    workspace?(Workspace.Project.config(path))
  end

  def workspace?(config) when is_list(config) do
    config[:workspace] != nil
  end

  defp mix_exs_path(path) do
    case String.ends_with?(path, "mix.exs") do
      true -> path
      false -> Path.join(path, "mix.exs")
    end
  end

  def apps_to_projects(workspace, apps) when is_list(apps) do
    Enum.map(apps, &project_by_app_name(workspace, &1))
  end

  def project_by_app_name(workspace, app) when is_atom(app) do
    case Map.has_key?(workspace.projects, app) do
      true -> workspace.projects[app]
      false -> raise KeyError, "no workspace project with app name #{inspect(app)}"
    end
  end

  @doc """
  Filter the `workspace` projects based on the given `opts`

  It will iterate over all projects and wil set the `:skip` to `true` if the
  project is considered skippable. The decision is made based on the passed
  options.

  A `Workspace` is returned with the projects statuses updated.

  ## Options

  * `:ignore` (`[atom]`) - a list of projects to be ignored. This has the highest
  priority, e.g. if the project is in the `:ignore` list it is always skipped.
  * `:project` (`[atom]`) - a list of project to consider, if set all projects that are
  not included in the list are considered skippable.
  * `:affected` (`boolean`) - if set only the affected projects will be included and
  everything else will be skipped, defaults to `false`

  Notice that projects are filtered using the following precedence:

  - `:ignore`
  - `:selected`
  - `:affected`
  """
  @spec filter_workspace(workspace :: Workspace.t(), opts :: keyword()) :: Workspace.t()
  def filter_workspace(%Workspace{} = workspace, opts) do
    projects = filter_projects(workspace, opts)

    set_projects(workspace, projects)
  end

  defp filter_projects(workspace, opts) do
    ignored = Enum.map(opts[:ignore] || [], &maybe_to_atom/1)
    selected = Enum.map(opts[:project] || [], &maybe_to_atom/1)
    affected = opts[:affected] || false
    modified = opts[:modified] || false
    only_roots = opts[:only_roots] || false

    affected_projects =
      case affected do
        false -> nil
        true -> affected(workspace)
      end

    modified_projects =
      case modified do
        false -> nil
        true -> modified(workspace)
      end

    Enum.map(workspace.projects, fn {_name, project} ->
      Map.put(
        project,
        :skip,
        skippable?(project, selected, ignored, affected_projects, modified_projects, only_roots)
      )
    end)
  end

  defp skippable?(
         %Workspace.Project{app: app, root?: root?},
         selected,
         ignored,
         affected,
         modified,
         only_roots
       ) do
    cond do
      # first we check if the project is in the ignore list
      app in ignored ->
        true

      # next we check if the project is not selected
      selected != [] and app not in selected ->
        true

      # if only_roots is set and the project is not a root skip it
      only_roots and not root? ->
        true

      # next we check if affected is set and the project is not affected
      is_list(affected) and app not in affected ->
        true

      # next we check if modified is set and the project is not modified
      is_list(modified) and app not in modified ->
        true

      # in any other case it is not skippable
      true ->
        false
    end
  end

  defp maybe_to_atom(value) when is_atom(value), do: value
  defp maybe_to_atom(value) when is_binary(value), do: String.to_atom(value)

  @doc """
  Returns the modified projects

  A workspace project is considered modified if any of it's files has
  changed with respect to the `base` branch.
  """
  @spec modified(workspace :: Workspace.t()) :: [Workspace.Project.t()]
  def modified(workspace) do
    with {:ok, changed_files} <- Workspace.Git.changed_files(cd: workspace.workspace_path) do
      changed_files
      |> Enum.map(fn file -> Path.join(workspace.workspace_path, file) |> Path.expand() end)
      |> Enum.map(fn file -> which_project(workspace, file) end)
      |> Enum.filter(fn project -> project != nil end)
      |> Enum.map(& &1.app)
      |> Enum.uniq()
    else
      {:error, reason} -> raise ArgumentError, "failed to get modified files: #{reason}"
    end
  end

  @doc """
  Returns the affected projects

  A project is considered affected if it has changed or any of it's children has
  changed.
  """
  @spec affected(workspace :: Workspace.t()) :: [atom()]
  def affected(workspace) do
    modified = modified(workspace)

    Workspace.Graph.affected(workspace, modified)
  end

  @doc """
  Returns the project the file belongs to, or `nil` in case of error.
  """
  @spec which_project(workspace :: Workspace.t(), path :: Path.t()) :: Workspace.Project.t() | nil
  def which_project(workspace, path) do
    Enum.reduce_while(Workspace.projects(workspace), nil, fn project, _acc ->
      case String.starts_with?(path, project.path) do
        true -> {:halt, project}
        false -> {:cont, nil}
      end
    end)
  end

  def update_projects_topology(workspace) do
    roots = Workspace.Graph.source_projects(workspace)

    projects =
      Enum.reduce(workspace.projects, %{}, fn {name, project}, acc ->
        project = Workspace.Project.set_root?(project, name in roots)

        Map.put_new(acc, name, project)
      end)

    %Workspace{workspace | projects: projects}
  end

  def update_projects_statuses(workspace) do
    affected =
      workspace
      |> affected()
      |> Enum.map(fn app -> {app, :affected} end)

    modified =
      workspace
      |> modified()
      |> Enum.map(fn app -> {app, :modified} end)

    # we must first check the affected since the modified may update the
    # status
    Enum.reduce(affected ++ modified, workspace, fn {app, status}, workspace ->
      set_project_status(workspace, app, status)
    end)
  end

  defp set_project_status(workspace, name, status) do
    projects =
      Map.update!(workspace.projects, name, fn project ->
        Workspace.Project.set_status(project, status)
      end)

    set_projects(workspace, projects)
  end
end
