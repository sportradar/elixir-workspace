defmodule Workspace.Project do
  @moduledoc """
  A struct holding a workspace project info
  """

  alias __MODULE__, as: Project

  @typedoc """
  Struct holding info about a mix project


  """
  @type t :: %Project{
          app: atom(),
          config: keyword(),
          mix_path: String.t(),
          path: String.t(),
          workspace_path: String.t()
        }

  @enforce_keys [:app, :config, :mix_path, :workspace_path, :path]
  defstruct app: nil,
            config: nil,
            mix_path: nil,
            path: nil,
            workspace_path: nil

  @doc """
  Creates a new project for the given project path.

  The `path` can be one of the following:

  - A path to a `mix.exs` file
  - A path to a project containing a `mix.exs` file

  You can pass both absolute and relative paths. All paths will
  be expanded by default.

  This will raise if the `path` does not correspond to a valid
  mix project.
  """
  @spec new(mix_path :: String.t(), workspace_path :: String.t()) :: t()
  def new(path, workspace_path) do
    mix_path =
      path
      |> Path.expand()
      |> mix_path()

    workspace_path = Path.expand(workspace_path)

    ensure_mix_file!(mix_path)

    in_project(
      Path.dirname(mix_path),
      fn module ->
        %__MODULE__{
          app: module.project()[:app],
          config: Mix.Project.config(),
          mix_path: mix_path,
          path: Path.dirname(mix_path),
          workspace_path: workspace_path
        }
      end
    )
  end

  defp mix_path(path) do
    case String.ends_with?(path, "mix.exs") do
      true -> path
      false -> Path.join(path, "mix.exs")
    end
  end

  def in_project(path, fun) do
    mix_path = mix_path(path)

    if mix_path == Mix.Project.project_file() do
      fun.(Mix.Project.get!())
    else
      Mix.Project.in_project(
        app_name(mix_path),
        Path.dirname(mix_path),
        fun
      )
    end
  end

  @doc """
  Returns the `Mix.Project` config of the given `mix.exs` file.

  The project will be loaded using `Mix.Project.in_project/4`.
  """
  @spec config(mix_path :: binary()) :: keyword()
  def config(mix_path) do
    in_project(mix_path, fn _module -> Mix.Project.config() end)
  end

  def relative_to_workspace(%Project{path: path, workspace_path: workspace_path}),
    do: Workspace.Utils.relative_path_to(path, workspace_path)

  # returns an "app name" for the given mix.exs file, it is the 
  # folder name containing the project. We need a conistent app name
  # for each mix.exs in order to avoid warnings for module redefinitions
  # when Mix.project.in_project is used. 
  #
  # Notice that in some edge cases if multiple projects in your workspace
  # have the same path this may cause incorrect behaviour. But you can
  # use the unique name check for avoiding such cases.
  defp app_name(mix_path) do
    mix_path
    |> Path.expand()
    |> Path.dirname()
    |> Path.basename()
    |> String.to_atom()
  end

  defp ensure_mix_file!(path) do
    cond do
      not String.ends_with?(path, "mix.exs") ->
        raise_no_mix_file(path)

      not File.exists?(path) ->
        raise_no_mix_file(path)

      true ->
        :ok
    end
  end

  defp raise_no_mix_file(path) do
    raise ArgumentError, "expected to get a valid path to a `mix.exs` file, got: #{path}"
  end
end
