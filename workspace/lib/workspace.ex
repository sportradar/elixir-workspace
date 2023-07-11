defmodule Workspace do
  @moduledoc """
  Documentation for `Workspace`.

  ## Defining a workspace

  A workspace is a normal `Mix.Project` with some tweaks:

  - No actual code is expected, so `:elixirc_paths` is set to `[]`
  - It must have a `:workspace` project option
  """

  @type t :: %Workspace{
          projects: [Workspace.Project.t()],
          config: Workspace.Config.t(),
          mix_path: binary(),
          workspace_path: binary(),
          cwd: binary()
        }

  @enforce_keys [:projects, :config, :mix_path, :workspace_path, :cwd]
  defstruct projects: [],
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
  @spec new(path :: binary(), config :: Workspace.Config.t() | binary()) :: t()
  def new(path, config \\ %Workspace.Config{})

  def new(path, config) when is_binary(config) do
    config_relative_path = Workspace.Utils.relative_path_to(config, Path.expand(path))

    config =
      Path.join(path, config_relative_path)
      |> Path.expand()
      |> config()

    new(path, config)
  end

  def new(path, %Workspace.Config{} = config) do
    workspace_mix_path = Path.join(path, "mix.exs") |> Path.expand()
    workspace_path = Path.dirname(workspace_mix_path)

    ensure_workspace!(workspace_mix_path)

    %__MODULE__{
      config: config,
      mix_path: workspace_mix_path,
      workspace_path: workspace_path,
      cwd: File.cwd!(),
      projects: projects(workspace_path, config)
    }
  end

  @doc """
  Tries to load the workspace config from the given path

  If the config cannot be loaded or is not valid, the default config is
  returned.
  """
  @spec config(path :: binary()) :: Workspace.Config.t()
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

        %Workspace.Config{}
    end
  end

  def file_project(workspace, path) do
    Enum.reduce_while(workspace.projects, nil, fn project, _acc ->
      case String.starts_with?(path, project.path) do
        true -> {:halt, project}
        false -> {:cont, nil}
      end
    end)
  end

  defp load_config_file(config_file) do
    config_file = Path.expand(config_file)

    case File.exists?(config_file) do
      false ->
        {:error, "file not found"}

      true ->
        {config, _bindings} = Code.eval_file(config_file)

        Workspace.Config.load(config)
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
      |> nested_mix_projects()
      |> Enum.filter(fn path -> not ignored_path?(path, config.ignore_paths, workspace_path) end)
      |> Enum.sort()
      |> Enum.map(fn path -> Workspace.Project.new(path, workspace_path) end)
      |> Enum.filter(&allowed_project?(&1, config))

    result
  end

  # TODO: add handling of nested workspaces
  defp nested_mix_projects(path) do
    subdirs = subdirs(path)

    projects = Enum.filter(subdirs, &mix_project?/1)
    remaining = subdirs -- projects

    Enum.reduce(remaining, projects, fn project, acc -> acc ++ nested_mix_projects(project) end)
  end

  defp subdirs(path) do
    path
    |> File.ls!()
    |> Enum.map(fn file -> Path.join(path, file) end)
    |> Enum.filter(&File.dir?/1)
  end

  defp mix_project?(path), do: File.exists?(Path.join(path, "mix.exs"))

  defp allowed_project?(project, config) do
    cond do
      project.module in config.ignore_projects ->
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

  @doc """
  Filter a set of `projects` based on the given `opts`

  The input can be either a list of `Workspace.Project` or a `Workspace`. In
  the latter case the workspace projects will be updated with the filtered
  ones.

  It will iterate over all projects and wil set the `:skip` to `true` if the
  project is considered skippable. The decision is made based on the passed
  options.

  ## Options

  * `:ignore` - a list of projects to be ignored. This has the highest
  priority, e.g. if the project is in the `:ignore` list it is always skipped.
  * `:project` - a list of project to consider, if set all projects that are
  not included in the list are considered skippable.
  """
  @spec filter_projects(projects :: [Workspace.Project.t()] | Workspace.t(), opts :: keyword()) ::
          [
            Workspace.Project.t()
          ]
  def filter_projects(%Workspace{} = workspace, opts) do
    projects = filter_projects(workspace.projects, opts)

    %Workspace{workspace | projects: projects}
  end

  def filter_projects(projects, opts) do
    ignored = Enum.map(opts[:ignore] || [], &maybe_to_atom/1)
    selected = Enum.map(opts[:project] || [], &maybe_to_atom/1)

    Enum.map(projects, fn project ->
      Map.put(project, :skip, skippable?(project, selected, ignored))
    end)
  end

  defp skippable?(%Workspace.Project{app: app}, selected, ignored) do
    cond do
      app in ignored -> true
      selected != [] and app not in selected -> true
      true -> false
    end
  end

  defp maybe_to_atom(value) when is_atom(value), do: value
  defp maybe_to_atom(value) when is_binary(value), do: String.to_atom(value)
end
