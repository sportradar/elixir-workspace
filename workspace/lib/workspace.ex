defmodule Workspace do
  @moduledoc """
  Documentation for `WorkspaceEx`.
  """

  # TODO: ensure this is a valid workspace root
  def root, do: File.cwd!()

  def relative_path(path), do: Path.relative_to(path, root())

  def projects(opts \\ []) do
    workspace_path =
      Keyword.get(opts, :workspace_path, ".")
      |> Path.expand()

    Path.wildcard(workspace_path <> "/**/mix.exs")
    # TODO: better filter out external dependencies
    |> Enum.filter(fn path ->
      Path.dirname(path) != workspace_path and !String.contains?(path, "deps")
    end)
    |> Enum.map(fn path -> Workspace.Project.new(path, workspace_path) end)
  end
end
