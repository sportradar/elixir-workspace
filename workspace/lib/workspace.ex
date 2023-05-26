defmodule Workspace do
  @moduledoc """
  Documentation for `WorkspaceEx`.
  """

  def projects do
    # TODO: ensure this is a valid workspace root
    workspace_root = File.cwd!()

    Path.wildcard(workspace_root <> "/**/mix.exs")
    # TODO: better filter out external dependencies
    |> Enum.filter(fn path ->
      Path.dirname(path) != workspace_root and !String.contains?(path, "deps")
    end)
    |> Enum.map(fn path -> package(path, workspace_root) end)
  end

  defp package(path, root_path) do
    relative_path = Path.relative_to(path, root_path)

    Mix.Project.in_project(
      String.to_atom(
        relative_path
        |> Path.dirname()
        |> Path.basename()
      ),
      Path.dirname(relative_path),
      fn mixfile ->
        %{
          app: mixfile.project()[:app],
          path: path,
          config: Mix.Project.config()
        }
      end
    )
  end
end
