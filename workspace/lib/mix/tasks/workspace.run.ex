defmodule Mix.Tasks.Workspace.Run do
  @shortdoc "Run a mix command to the given projects"

  use Mix.Task

  def run(argv) do
    {args, argv, extra_args} =
      case CliOpts.validate(argv, Workspace.Cli.global_opts()) do
        {:error, reason} -> Mix.raise(reason)
        args -> args
      end

    Workspace.projects()
    |> Workspace.Cli.filter_projects(args, argv)
    |> Enum.each(fn project -> run_in_project(project, args, extra_args) end)
  end

  defp run_in_project(%{skip: true, app: app}, args, _argv) do
    if args[:verbose] do
      WorkspaceColors.warning("#{args[:task]}", "skipping #{app}")
    end
  end

  defp run_in_project(project, args, argv) do
    WorkspaceColors.info("#{args[:task]}", "#{project[:app]}")

    Mix.Project.in_project(project[:app], Path.dirname(project[:path]), fn _mixfile ->
      Mix.Task.run(args[:task], argv)
    end)
  end
end
