defmodule Workspace.Topology do
  @moduledoc """
  Helper utilities related to the workspace's topology.
  """

  @doc """
  Returns the project the file belongs to, or `nil` in case of error.
  """
  @spec parent_project(workspace :: Workspace.t(), path :: Path.t()) ::
          Workspace.Project.t() | nil
  def parent_project(workspace, path) do
    path = Path.expand(path, workspace.workspace_path)

    Enum.reduce_while(workspace.projects, nil, fn {_app, project}, _acc ->
      case Workspace.Utils.Path.parent_dir?(project.path, path) do
        true -> {:halt, project}
        false -> {:cont, nil}
      end
    end)
  end
end
