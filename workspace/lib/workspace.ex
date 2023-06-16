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
          config: [],
          mix_path: binary(),
          workspace_path: binary(),
          cwd: binary()
        }

  @enforce_keys [:projects, :config, :mix_path, :workspace_path, :cwd]
  defstruct projects: [],
            config: [],
            mix_path: nil,
            workspace_path: nil,
            cwd: nil

  @doc """
  Creates a new `Workspace` from the given workspace path

  `config` is an optional keyword list with the workspace's config.
  """
  @spec new(path :: binary(), config :: Workspace.Config.t()) :: t()
  def new(path, config \\ %Workspace.Config{}) do
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

      ignored_path?(project.mix_path, config.ignore_paths, project.workspace_path) ->
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
end
