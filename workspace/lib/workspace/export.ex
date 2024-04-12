defmodule Workspace.Export do
  @moduledoc """
  Helper utilities for exporting the workspace to various formats.
  """

  @compile {:no_warn_undefined, {Jason, :encode!, 2}}

  @doc """
  Returns a `json` representation of the key workspace properties.

  By default only the `workspace_path` and the `projects` are included.

  Notice that skipped projects are not included.
  """
  @spec to_json(workspace :: Workspace.State.t()) :: String.t()
  def to_json(workspace) do
    assert_jason!("to_json/1")

    %{
      workspace_path: workspace.workspace_path,
      projects:
        workspace.projects
        |> Enum.reject(fn {_name, project} -> project.skip end)
        |> Enum.map(fn {_name, project} -> Workspace.Project.to_map(project) end)
    }
    |> Jason.encode!(pretty: true)
  end

  @doc false
  @spec assert_jason!(fn_name :: String.t()) :: :ok
  def assert_jason!(fn_name) do
    unless Code.ensure_loaded?(Jason) do
      raise RuntimeError, """
      #{fn_name} depends on the :jason package.

      You can install it by adding

          {:jason, "~> 1.4"}

      to your dependency list.
      """
    end

    :ok
  end
end
