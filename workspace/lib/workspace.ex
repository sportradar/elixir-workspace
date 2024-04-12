defmodule Workspace do
  @moduledoc """
  A `Workspace` is a collection of mix projects under the same git repo.

  `Workspace` provides a set of tools for working with multiple projects under
  the same git repo. Using path dependencies between the projects and the
  provided tools you can effectively work on massive codebases properly
  split into reusable packages.

  ## Structuring a folder as a workspace root

  A workspace is a normal `Mix.Project` with some tweaks:

    * No actual code is expected, so `:elixirc_paths` is set to `[]`
    * It must have a `:workspace` project option configured with a `:type` set
    to `:workspace`.

  ```elixir
  def project do
    [
      workspace: [
        type: :workspace,
        # arbitrary options can be set there
      ],
      # rest Mix.Project settings
    ]
  end
  ```

  A generator is provided for bootstrapping a new workspace project:

      $ mix workspace.new NAME

  ## Workspace projects

  A mix project is considered a workspace project if:

    * it is located in a subfolder of the workspace root path
    * it is not included in the ignored projects or ignored paths in the
    workspace config

  Assuming the folder structure:

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

  In the above example:

    * We have defined a `Workspace` under `my_workspace` folder
    * All mix projects under `my_workspace` are by default considered
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

  ## Loading a workspace

  A `Workspace` can be constructed by calling the `new/2` function. It
  will use the given path and config object in order to load and validate
  all internal projects.

  ## The workspace graph

  The most important concept of the `Workspace` is the projects graph. The
  project graph is a directed acyclic graph where each vertex is a project
  and each edge a dependency between the two projects.

  The workspace graph is constructed implicitly upon workspace's creation
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
  > package_a
  > ├── package_b
  > │   └── package_g
  > ├── package_c
  > │   ├── package_e
  > │   └── package_f
  > │       └── package_g
  > └── package_d
  > package_h
  > └── package_d
  > package_i
  > └── package_j
  > package_k
  > ```
  >
  > You can additionally plot is as mermaid graph by specifying the
  > `--format mermaid` flag:
  >
  > ```mermaid
  > flowchart TD
  > package_a
  > package_b
  > package_c
  > package_d
  > package_e
  > package_f
  > package_g
  > package_h
  > package_i
  > package_j
  > package_k
  >
  > package_a --> package_b
  > package_a --> package_c
  > package_a --> package_d
  > package_b --> package_g
  > package_c --> package_e
  > package_c --> package_f
  > package_f --> package_g
  > package_h --> package_d
  > package_i --> package_j
  > ```

  ## Workspace filtering

  As your workspace grows running a CI task on all projects becomes too slow.
  To address this, code change analysis is supported in order to get the minimum
  set of projects that need to be executed.

  `Workspace` supports various filtering modes. Each one should be used in
  context with the underlying task. For more details check `filter/2`.

  ### Global filtering options

    * `:ignored` - ignores these specific projects
    * `:selected` - considers only these projects
    * `:only_roots` - considers only the graph roots (sources), e.g. ignores
    all projects that have a parent in the graph.

  ### Code analysis related options

    * `:modified` - returns only the modified projects, e.g. projects for which
    the code has changed
    * `:affected` - returns all affected projects. Affected projects are the
    modified ones plus the 

  `:modified` and `:affected` can be combined with the global filtering options.

  > #### Understanding when and how to filter a workspace {: .info}
  >
  > Workspace filtering should be actively used on big workspaces in order to
  > improve the local build and CI times.
  >
  > Some examples follow:
  >
  >   - If a workspace is used by multiple teams and contains multiple apps, you
  > should select a specific top level app when building the project. This will
  > ignore all other irrelevant apps.
  >   - When changing a specific set of projects, you should use `:modified` for
  > formatting the code since everything else is not affected. 
  >   - Similarly for testing you should use the `:affected` filtering since a
  > change on a project may affect all parents.
  >   - It is advised to have generic CI pipelines on master/main branches that
  > do not apply any filtering.

  > #### Visualizing what is affected {: .tip}
  >
  > You can use the `--show-status` flag in most of `workspace` to indicate what
  > is unchanged, modified or affected.
  >
  > For instance if you have changed `package_f` and `package_d` you can visualize
  > the graph using `workspace.graph --format mermaid --show-status`
  >
  > ```mermaid
  > flowchart TD
  >   package_a
  >   package_b
  >   package_c
  >   package_d
  >   package_e
  >   package_f
  >   package_g
  >   package_h
  >   package_i
  >
  >   package_a --> package_b
  >   package_a --> package_c
  >   package_a --> package_d
  >   package_b --> package_g
  >   package_c --> package_e
  >   package_c --> package_f
  >   package_f --> package_g
  >   package_h --> package_d
  >   package_i --> package_b
  >
  >   class package_a affected;
  >   class package_c affected;
  >   class package_d modified;
  >   class package_f modified;
  >   class package_h affected;
  >
  >   classDef affected fill:#FA6,color:#FFF;
  >   classDef modified fill:#F33,color:#FFF;
  > ```
  > 
  > Modified projects are indicated with red colors, and affected projects are
  > highlighted with orange color.
  >
  > You could now use the proper filtering flags based on what you want to run:
  >
  > ```bash
  > # We want to build only the top level affected projects
  > mix workspace.run -t compile --only-roots --affected
  >
  > # we want to format only the modified ones
  > mix workspace.run -t format --modified
  >
  > # we want to test all the affected ones
  > mix workspace.run -t test --affected
  > ```

  ## Environment variables

  The following environment variables are supported:

  * `WORKSPACE_DEBUG` - if then debug information will be printed.

  Environment variables that are not meant to hold a value (and act basically as
  flags) should be set to either `1` or `true`, for example:

      $ WORKSPACE_DEBUG=true mix workspace.check
  """

  @doc """
  Similar to `new/2` but raises in case of error.
  """
  @spec new!(path :: binary(), config :: keyword() | binary()) :: Workspace.State.t()
  def new!(path, config \\ []) do
    case new(path, config) do
      {:ok, workspace} -> workspace
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Creates a new `Workspace` from the given workspace path

  `config_or_path` can be one of the following:

    * A path relative to the workspace root path pointing to the workspace config
    (`.workspace.exs` in most cases)
    * A keyword list with the config

  The workspace is created by finding all valid mix projects under
  the workspace root.

  Returns `{:ok, workspace}` in case of success, or `{:error, reason}`
  if something fails.
  """
  @spec new(path :: binary(), config_or_path :: keyword() | binary()) ::
          {:ok, Workspace.State.t()} | {:error, binary()}
  def new(path, config_or_path \\ [])

  def new(path, config_or_path) when is_binary(config_or_path) do
    config_path = Workspace.Utils.Path.relative_to(config_or_path, Path.expand(path))
    config_path = Path.join(path, config_path)

    with {:ok, config} <- Workspace.Config.load(config_path) do
      new(path, config)
    end
  end

  def new(path, config_or_path) when is_list(config_or_path) do
    workspace_mix_path = Path.join(path, "mix.exs") |> Path.expand()
    workspace_path = Path.dirname(workspace_mix_path)

    Workspace.Cli.debug("initializing workspace under #{path}")

    with {:ok, config} <- Workspace.Config.validate(config_or_path),
         :ok <- ensure_workspace(workspace_mix_path),
         projects <- Workspace.Finder.projects(workspace_path, config) do
      new(workspace_path, workspace_mix_path, config, projects)
    end
  end

  @doc false
  @spec new(
          workspace_path :: String.t(),
          workspace_mix_path :: String.t(),
          config :: keyword(),
          projects :: [Workspace.Project.t()]
        ) :: {:ok, Workspace.State.t()} | {:error, String.t()}
  def new(workspace_path, workspace_mix_path, config, projects) do
    with {:ok, projects} <- ensure_unique_names(projects) do
      workspace = Workspace.State.new(workspace_path, workspace_mix_path, config, projects)
      Workspace.Cli.debug("initialized a workspace with #{length(projects)} projects")

      {:ok, workspace}
    end
  end

  defp ensure_workspace(path) do
    with {:ok, path} <- Workspace.Helpers.ensure_file_exists(path),
         config <- Workspace.Project.config(path),
         :ok <- ensure_workspace_set_in_config(config) do
      :ok
    else
      {:error, reason} ->
        {
          :error,
          """
          Expected #{path} to be a workspace project. Some errors were detected:

          #{reason}
          """
        }
    end
  end

  defp ensure_workspace_set_in_config(config) when is_list(config) do
    if Workspace.Project.project_type(config) == :workspace do
      :ok
    else
      {:error,
       """
       The project is not properly configured as a workspace.

       In order to define a project as a workspace, you need to add the following
       to the project's `mix.exs` config:

           workspace: [
             type: :workspace
           ]
       """}
    end
  end

  defp ensure_unique_names(projects) do
    invalid_projects =
      projects
      |> Enum.group_by(& &1.app)
      |> Enum.filter(fn {_app, projects} -> length(projects) > 1 end)

    case invalid_projects do
      [] ->
        {:ok, projects}

      invalid ->
        error_message =
          Enum.map_join(invalid, "\n", fn {app, projects} ->
            paths =
              Enum.map_join(
                projects,
                ", ",
                &Workspace.Utils.Path.relative_to(&1.mix_path, &1.workspace_path)
              )

            "* #{inspect(app)} is defined under: #{paths}"
          end)

        error_message =
          """
          You are not allowed to have multiple projects with the same name under
          the same workspace.

          #{error_message}
          """

        {:error, error_message}
    end
  end

  @doc """
  Returns the workspace projects as a list.
  """
  @spec projects(workspace :: Workspace.State.t()) :: [Workspace.Project.t()]
  def projects(workspace) do
    workspace.projects
    |> Map.values()
    |> Enum.sort_by(fn project -> project.app end)
  end

  @doc """
  Returns `true` if the given `app` is a `workspace` project, `false` otherwise. 
  """
  @spec project?(workspace :: Workspace.State.t(), app :: atom()) :: boolean()
  def project?(workspace, app) when is_struct(workspace, Workspace.State) and is_atom(app),
    do: Map.has_key?(workspace.projects, app)

  @doc """
  Similar to `project/2` but raises in case of error
  """
  @spec project!(workspace :: Workspace.State.t(), app :: atom()) :: Workspace.Project.t()
  def project!(workspace, app) do
    case project(workspace, app) do
      {:ok, project} -> project
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Get the given project from the workspace.

  If the project is not a workspace member, an error tuple is returned.
  """
  @spec project(workspace :: Workspace.State.t(), app :: atom()) ::
          {:ok, Workspace.Project.t()} | {:error, binary()}
  def project(workspace, app) when is_atom(app) do
    case Map.has_key?(workspace.projects, app) do
      true -> {:ok, workspace.projects[app]}
      false -> {:error, "#{inspect(app)} is not a member of the workspace"}
    end
  end
end
