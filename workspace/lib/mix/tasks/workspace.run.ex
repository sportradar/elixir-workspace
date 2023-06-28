defmodule Mix.Tasks.Workspace.Run do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path,
                    :project,
                    :task,
                    :affected,
                    :ignore,
                    :execution_order,
                    :execution_mode,
                    :verbose,
                    :dry_run
                  ])

  @shortdoc "Run a mix command to all projects"

  @moduledoc """

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """

  use Mix.Task

  def run(argv) do
    {:ok, opts} = CliOpts.parse(argv, @options_schema)
    %{parsed: opts, args: args, extra: extra, invalid: invalid} = opts

    task_args = CliOpts.to_list(invalid) ++ extra ++ args

    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    config = Workspace.config(Path.join(workspace_path, config_path))
    workspace = Workspace.new(workspace_path, config)

    workspace.projects
    |> Workspace.Cli.filter_projects(opts)
    |> Enum.map(fn project -> run_in_project(project, opts, task_args) end)
    |> raise_if_any_task_failed()
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

    if not options[:dry_run] do
      run_task(project, task, argv, options)
    end
  end

  defp run_task(project, task, argv, options) do
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

    status_code = stream_output([args: args, project: project, task: full_task], port)

    case status_code do
      0 -> :ok
      _other -> {:error, "#{full_task} failed in #{project.app}"}
    end
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

        status
    end
  end

  defp raise_if_any_task_failed(task_results) do
    failures =
      Enum.filter(task_results, fn result ->
        case result do
          {:error, _reason} -> true
          _other -> false
        end
      end)

    if length(failures) > 0 do
      Mix.raise("mix workspace.run failed - errors detected in #{length(failures)} executions")
    end
  end
end
