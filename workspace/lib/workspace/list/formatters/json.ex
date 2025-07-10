defmodule Workspace.List.Formatters.Json do
  @moduledoc false

  @behaviour Workspace.List.Formatter

  @impl Workspace.List.Formatter
  def render(workspace, opts) do
    relative = opts[:relative_paths]

    workspace_path =
      case relative do
        true -> "."
        false -> workspace.workspace_path
      end

    projects =  workspace.projects
    |> Enum.reject(fn {_name, project} -> project.skip end)
    |> Enum.map(fn {_name, project} ->
      Workspace.Project.to_map(project, relative: relative) |> Map.take([:app, :path])
    end)

    %{
      workspace_path: workspace_path,
      projects: %{
        count: Enum.count(projects),
        projects: projects
      }
    }
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end
end
