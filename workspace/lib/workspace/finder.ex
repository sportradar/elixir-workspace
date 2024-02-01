defmodule Workspace.Finder do
  @moduledoc false

  # Module responsible for finding projects under a workspace root.

  @default_ignored_paths [".git", "_build", ".elixir_ls"]

  @doc """
  Find all nested mix projects under the given path.

  ## Options

  * `:ignore_paths` - list of paths to ignore
  * `:ignore_projects` - list of projects to ignore
  """
  @spec projects(path :: String.t(), opts :: keyword()) :: [Workspace.Project.t()]
  def projects(workspace_path, opts) do
    ignored_paths = Keyword.fetch!(opts, :ignore_paths) ++ @default_ignored_paths

    projects =
      workspace_path
      |> nested_mix_projects(ignored_paths, workspace_path)
      |> Enum.map(fn path -> Workspace.Project.new(path, workspace_path) end)
      |> Enum.filter(&ignored_project?(&1, opts[:ignore_projects]))

    projects
  end

  defp nested_mix_projects(path, ignore_paths, workspace_path) do
    # TODO: pass verbose and if set print checked paths
    subdirs = subdirs(path, ignore_paths, workspace_path)

    projects = Enum.filter(subdirs, &mix_project?/1)
    remaining = subdirs -- projects

    Enum.reduce(remaining, projects, fn project, acc ->
      acc ++ nested_mix_projects(project, ignore_paths, workspace_path)
    end)
  end

  defp subdirs(path, ignore_paths, workspace_path) do
    path
    |> File.ls!()
    |> Enum.map(fn file -> Path.join(path, file) end)
    |> Enum.filter(fn path ->
      File.dir?(path) and not ignored_path?(path, ignore_paths, workspace_path)
    end)
  end

  defp mix_project?(path), do: File.exists?(Path.join(path, "mix.exs"))

  defp ignored_project?(project, ignore_projects) do
    cond do
      project.module in ignore_projects ->
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
end
