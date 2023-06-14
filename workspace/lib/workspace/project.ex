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
          workspace_path: String.t(),
          cwd: String.t(),
          path: String.t()
        }

  @enforce_keys [:app, :config, :mix_path, :workspace_path, :cwd, :path]
  defstruct app: nil,
            config: nil,
            mix_path: nil,
            path: nil,
            workspace_path: nil,
            cwd: nil

  @doc """
  Creates a new project for the given `mix.exs` path

  Notice that the calculated paths are relative to the current working
  directory, so you should invoke this function in order to generate new
  project info structure from the root of your workspace.
  """
  @spec new(mix_path :: String.t(), workspace_path :: String.t()) :: t()
  def new(mix_path, workspace_path) do
    cwd = File.cwd!()

    relative_path = Path.relative_to(mix_path, cwd)

    app =
      relative_path
      |> Path.dirname()
      |> Path.basename()
      |> String.to_atom()

    Mix.Project.in_project(
      app,
      Path.dirname(relative_path),
      fn module ->
        %__MODULE__{
          app: module.project()[:app],
          config: Mix.Project.config(),
          mix_path: mix_path,
          path: Path.dirname(mix_path),
          workspace_path: workspace_path,
          cwd: cwd
        }
      end
    )
  end

  def relative_path(%__MODULE__{cwd: cwd, path: path}), do: Path.relative_to(path, cwd)

  @doc """
  Returns the `Mix.Project` config of the given `mix.exs` file.

  The project will be loaded using `Mix.Project.in_project/4`.
  """
  @spec config(mix_path :: binary()) :: keyword()
  def config(mix_path) do
    path =
      mix_path
      |> Path.expand()
      |> Path.dirname()

    Mix.Project.in_project(
      app_name(mix_path),
      path,
      fn _module -> Mix.Project.config() end
    )
  end

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
end
