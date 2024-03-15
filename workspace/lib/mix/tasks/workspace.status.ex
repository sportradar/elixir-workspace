defmodule Mix.Tasks.Workspace.Status do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path,
                    :base,
                    :head
                  ])

  @shortdoc "Display workspace's projects status."

  @moduledoc """
  Similar to `git status` but on a workspace level.

      $ mix workspace.status

  ## Command line options

  #{CliOptions.docs(@options_schema, sort: true)}
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _args, _extra} = CliOptions.parse!(args, @options_schema, as_tuple: true)

    opts
    |> Keyword.merge(show_status: true)
    |> Mix.WorkspaceUtils.load_and_filter_workspace()
    |> show_status()
  end

  defp show_status(workspace) do
    modified = Workspace.Status.modified(workspace)
    affected = Workspace.Status.affected(workspace)

    show_modified(workspace, modified)
    show_affected(workspace, affected -- modified)
  end

  defp show_modified(_workspace, []), do: :ok

  defp show_modified(workspace, modified) do
    Workspace.Cli.log([:light_gray, "Modified projects:", :reset])

    Enum.each(modified, fn name ->
      project = Workspace.project!(workspace, name)
      print_project_status(project, :modified)
      print_changes(project)
    end)

    Workspace.Cli.newline()
  end

  defp show_affected(_workspace, []), do: :ok

  defp show_affected(workspace, affected) do
    Workspace.Cli.log([:light_gray, "Affected projects:", :reset], prefix: "")

    Enum.each(affected, fn name ->
      print_project_status(Workspace.project!(workspace, name), :affected)
    end)

    Workspace.Cli.newline()
  end

  defp print_project_status(project, color) do
    Workspace.Cli.log([
      "  ",
      color,
      inspect(project.app),
      :reset,
      :mix_path,
      " ",
      Path.relative_to(project.mix_path, project.workspace_path),
      :reset
    ])
  end

  defp print_changes(project) do
    for {path, change_type} <- project.changes do
      Workspace.Cli.log([
        "    ",
        change_type_color(change_type),
        change_type(change_type),
        " ",
        path,
        :reset
      ])
    end
  end

  defp change_type_color(:untracked), do: :gold
  defp change_type_color(_other), do: :pink

  defp change_type(:untracked), do: "untracked"
  defp change_type(_other), do: "modified "
end
