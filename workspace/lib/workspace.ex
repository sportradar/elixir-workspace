defmodule Workspace do
  @moduledoc """
  Documentation for `Workspace`.

  ## Defining a workspace

  A workspace is a normal `Mix.Project` with some tweaks:

  - No actual code is expected, so `:elixirc_paths` is set to `[]`
  - It must have a `:workspace` project option
  """

  @doc """
  Returns the projects of the given workspace
  """
  @spec projects(opts :: keyword()) :: [Workspace.Project.t()]
  def projects(opts \\ []) do
    workspace_path =
      Keyword.get(opts, :workspace_path, ".")
      |> Path.expand()

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
