defmodule Mix.Tasks.Workspace.Run do
  @options_schema Workspace.Cli.options([
                    :affected,
                    :ignore,
                    :task,
                    :execution_order,
                    :execution_mode,
                    :verbose,
                    :workspace_path,
                    :config_path
                  ])

  @shortdoc "Run a mix command to all projects"

  @moduledoc """

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """

  use Mix.Task

  def run(argv) do
    %{parsed: opts, args: args, extra: extra} = CliOpts.parse!(argv, @options_schema)
    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    config = Workspace.config(Path.join(workspace_path, config_path))
    workspace = Workspace.new(workspace_path, config)

    workspace.projects
    |> Workspace.Cli.filter_projects(opts, args)
    |> Enum.each(fn project -> run_in_project(project, opts, extra) end)
  end

  defp run_in_project(%{skip: true, app: app}, args, _argv) do
    if args[:verbose] do
      Workspace.Cli.warning("#{args[:task]}", "skipping #{app}")
    end
  end

  defp run_in_project(project, options, argv) do
    task = options[:task]

    task_args = [task | argv]

    Mix.shell().info([
      :cyan,
      "==> ",
      Workspace.Project.relative_to_workspace(project),
      :reset,
      " - ",
      :bright,
      "mix #{Enum.join(task_args, " ")}",
      :reset
    ])

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
    full_task = ~s'mix #{Enum.join([task | argv], " ")}'
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

    stream_output([args: args, project: project, task: full_task], port)
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
        task = Keyword.get(meta, :task)
        project = Keyword.get(meta, :project)

        Mix.shell().error([
          "==> ",
          Workspace.Project.relative_to_workspace(project),
          :reset,
          " - ",
          :bright,
          :light_red,
          :underline,
          task,
          :reset,
          " failed with #{status}"
        ])
    end
  end
end
