defmodule Mix.Tasks.Workspace.List do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path,
                    :project,
                    :ignore,
                    :show_status
                  ])

  @shortdoc "Display info about the workspace projects"

  @moduledoc """
  Shows workspace project info

      $ mix workspace.list

  By default the following are displayed:

  - the project app name
  - the project path with respect to workspace path
  - the description if set

  ## Command line options

  #{CliOpts.docs(@options_schema)}
  """
  use Mix.Task
  alias Workspace.Cli

  @impl true
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts, args: _args, extra: _extra, invalid: _invalid} = opts

    opts
    |> Mix.WorkspaceUtils.load_and_filter_workspace()
    |> list_workspace_projects(opts[:show_status])
  end

  defp list_workspace_projects(workspace, show_status) do
    max_project_length =
      workspace
      |> Workspace.projects()
      |> Enum.map(fn project -> inspect(project.app) |> String.length() end)
      |> Enum.max()

    Enum.each(
      Workspace.projects(workspace),
      &print_project_info(&1, max_project_length, show_status)
    )
  end

  defp print_project_info(%Workspace.Project{skip: true}, _length, _show_status), do: :ok

  defp print_project_info(project, max_project_length, show_status) do
    indent_size = max_project_length - String.length(inspect(project.app))
    indent = String.duplicate(" ", indent_size)

    Cli.log([
      "  * ",
      Cli.project_name(project, show_status: show_status, pretty: true),
      indent,
      :light_black,
      " ",
      Path.relative_to(project.mix_path, project.workspace_path),
      :reset,
      description(project.config[:description])
    ])
  end

  defp description(nil), do: ""
  defp description(doc) when is_binary(doc), do: [" - ", doc]
end
