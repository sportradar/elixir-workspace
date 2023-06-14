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

  defstruct projects: [],
            config: [],
            mix_path: nil,
            workspace_path: nil,
            cwd: nil

  @doc """
  Creates a new `Workspace` from the given workspace path
  """
  def new(path \\ File.cwd!()) do
    workspace_mix_path = Path.join(path, "mix.exs") |> Path.expand()
    workspace_path = Path.dirname(workspace_mix_path)

    ensure_workspace!(workspace_mix_path)

    workspace_config = Workspace.Project.config(workspace_mix_path)[:workspace]

    %__MODULE__{
      config: workspace_config,
      mix_path: workspace_mix_path,
      workspace_path: workspace_path,
      cwd: File.cwd!(),
      projects: projects(workspace_path, workspace_config)
    }
  end

  @doc """
  Returns the projects of the given workspace
  """
  @spec projects(workspace_path :: binary(), opts :: keyword()) :: [Workspace.Project.t()]
  def projects(workspace_path, _opts \\ []) do
    ensure_workspace!(workspace_path)

    Path.wildcard(workspace_path <> "/**/mix.exs")
    # TODO: better filter out external dependencies
    |> Enum.filter(fn path ->
      Path.dirname(path) != workspace_path and !String.contains?(path, "deps")
    end)
    |> Enum.map(fn path -> Workspace.Project.new(path, workspace_path) end)
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

  @doc """
  Returns `true` if the given project is a workspace

  It expects one of the following:

  * a project config
  * a path to a `mix.exs` file
  * a path to a folder containing a root folder

  If a path is provided then the config of the project will be loaded first.

  If a path is provided then it will be expanded first.

  When called with no arguments, tells whether the current project is a
  workspace or not.

  Raises if a path is provided which does not resolve to a valid `mix.exs`
  file.
  """
  @spec workspace?(config_or_path :: keyword() | binary()) :: boolean()
  def workspace?(config_or_path \\ Mix.Project.config())

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

    if path == Mix.Project.project_file() do
      workspace?(Mix.Project.config())
    else
      workspace?(Workspace.Project.config(path))
    end
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
