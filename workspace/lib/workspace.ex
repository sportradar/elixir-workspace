defmodule Workspace do
  @moduledoc """
  Documentation for `WorkspaceEx`.
  """

  # TODO: ensure this is a valid workspace root
  def root, do: File.cwd!()

  def relative_path(path), do: Path.relative_to(path, root())

  def projects(opts \\ []) do
    workspace_root =
      Keyword.get(opts, :workspace_path, ".")
      |> Path.expand()

    Path.wildcard(workspace_root <> "/**/mix.exs")
    # TODO: better filter out external dependencies
    |> Enum.filter(fn path ->
      Path.dirname(path) != workspace_root and !String.contains?(path, "deps")
    end)
    |> Enum.map(fn path -> package(path, File.cwd!()) end)
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
