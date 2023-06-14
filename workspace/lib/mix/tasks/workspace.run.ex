defmodule Mix.Tasks.Workspace.Run do
  @options_schema Workspace.Cli.global_opts()

  @shortdoc "Run a mix command to all projects"

  @moduledoc """

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """

  use Mix.Task

  alias Workspace.Cli

  def run(argv) do
    %{parsed: parsed, args: args, extra: extra} = CliOpts.parse!(argv, @options_schema)

    workspace = Workspace.new(File.cwd!())

    workspace.projects
    |> Workspace.Cli.filter_projects(parsed, args)
    |> Enum.each(fn project -> run_in_project(project, parsed, extra) end)
  end

  defp run_in_project(%{skip: true, app: app}, args, _argv) do
    if args[:verbose] do
      Workspace.Cli.warning("#{args[:task]}", "skipping #{app}")
    end
  end

  defp run_in_project(project, options, argv) do
    task = options[:task]

    task_args = [task | argv]

    Cli.info(
      Workspace.Project.relative_to_workspace(project),
      "- mix #{Enum.join(task_args, " ")}",
      prefix: "==> "
    )

    case options[:execution_mode] do
      "process" ->
        cmd(task, argv, project)

      "subtask" ->
        Mix.Project.in_project(
          project.app,
          project.path,
          fn _mixfile ->
            Mix.Task.run(task, argv)
          end
        )

      other ->
        Mix.raise("invalid execution mode #{other}, only `process` and `subtask` are supported")
    end
  end

  defp cmd(task, argv, project) do
    [command | args] = enable_ansi(["mix", task | argv])

    command = System.find_executable(command)

    port =
      Port.open({:spawn_executable, command}, [
        :stream,
        :hide,
        :use_stdio,
        :stderr_to_stdout,
        :binary,
        :exit_status,
        args: args,
        cd: project.path
      ])

    stream_output([args: args, project: project], port)
  end

  # elixir tasks are not run in a TTY and will by default not print ANSI
  # characters, We explicitely enable ANSI 
  # kudos to `ex_check`: https://github.com/karolsluszniak/ex_check
  defp enable_ansi(["mix" | args]) do
    erl_config = Application.app_dir(:workspace, ~w[priv enable_ansi.config])

    ["elixir", "--erl-config", erl_config, "-S", "mix" | args]
  end

  defp enable_ansi(cmd), do: cmd

  defp stream_output(meta, port) do
    receive do
      {^port, {:data, data}} ->
        IO.write(data)
        stream_output(meta, port)

      {^port, {:exit_status, 0}} ->
        0

      {^port, {:exit_status, status}} ->
        args = Keyword.get(meta, :args)
        project = Keyword.get(meta, :project)

        Cli.error(
          Workspace.Project.relative_to_workspace(project),
          "- mix #{Enum.join(args, " ")} failed with #{status}",
          prefix: "==> "
        )
    end
  end
end
