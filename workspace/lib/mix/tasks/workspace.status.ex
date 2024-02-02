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

  #{CliOpts.docs(@options_schema, sort: true)}
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts, args: _args, extra: _extra, invalid: _invalid} = opts

    opts
    |> Keyword.merge(show_status: true)
    |> Mix.WorkspaceUtils.load_and_filter_workspace()
    |> show_status()
  end

  defp show_status(workspace) do
    modified = projects_with_status(workspace, :modified)
    affected = projects_with_status(workspace, :affected)

    show_modified(workspace, modified)
    show_affected(workspace, affected -- modified)
  end

  defp projects_with_status(workspace, status) do
    workspace.projects
    |> Enum.filter(fn {_app, project} -> project.status == status end)
    |> Enum.map(fn {app, _project} -> app end)
  end

  defp show_modified(_workspace, []), do: :ok

  defp show_modified(workspace, modified) do
    Workspace.Cli.log([:light_gray, "Modified projects:", :reset])

    Enum.each(modified, fn name ->
      print_project(Workspace.project!(workspace, name), :modified)
    end)

    Workspace.Cli.newline()
  end

  defp show_affected(_workspace, []), do: :ok

  defp show_affected(workspace, affected) do
    Workspace.Cli.log([:light_gray, "Affected projects:", :reset], prefix: "")

    Enum.each(affected, fn name ->
      print_project(Workspace.project!(workspace, name), :affected)
    end)

    Workspace.Cli.newline()
  end

  defp print_project(project, color) do
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
end
