defmodule Mix.Tasks.Workspace.Format do
  @shortdoc "Formats all workspace projects"

  @opts [
    affected: [
      type: :boolean,
      alias: :a,
      doc: "Run only on affected projects"
    ],
    project: [
      type: :string,
      alias: :p,
      keep: true,
      doc: "Run the command only on the specified projects"
    ]
  ]
  use Mix.Task

  def run(argv) do
    {workspace_argv, task_argv} = CliOpts.split_argv(argv)

    {_workspace_opts, args, _other} =
      OptionParser.parse(workspace_argv,
        strict: CliOpts.switches(@opts),
        aliases: CliOpts.aliases(@opts)
      )

    filter_projects(args)
    |> Enum.each(fn {name, path, _config} -> format_project(name, path, task_argv) end)
  end

  defp format_project(name, path, argv) do
    WorkspaceColors.info("formatting", "#{name}")

    Mix.Project.in_project(name, Path.dirname(path), fn _mixfile ->
      Mix.Task.run("format", argv)
    end)
  end

  defp filter_projects([]), do: Workspace.projects()

  defp filter_projects(input_projects) do
    Workspace.projects()
    |> Enum.reduce([], fn project, acc ->
      {name, _path, _config} = project

      case Atom.to_string(name) in input_projects do
        true ->
          [project | acc]

        false ->
          WorkspaceColors.warning("skipping", "#{name}")
          acc
      end
    end)
  end
end
