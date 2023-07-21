defmodule Mix.Tasks.Workspace.Run do
  @task_options [
    task: [
      type: :string,
      alias: :t,
      doc: "The task to execute",
      required: true
    ],
    execution_mode: [
      type: :string,
      default: "process",
      doc: """
      The execution mode. It supports the following values:

        - `process` - every subcommand will be executed as a different process, this
        is the preferred mode for most mix tasks
        - `in-project` - invokes `Mix.Task.run` from the workspace in the given project
        without creating a new process (**notice that this is experimental and may not work properly
        for some commands**)

      """
    ],
    only_roots: [
      type: :boolean,
      doc: "If set, the task will be executed only on graph's root nodes."
    ],
    dry_run: [
      type: :boolean,
      doc: "If set it will not execute the command, useful for testing and debugging.",
      default: false
    ],
    env_var: [
      type: :string,
      doc: """
      Optional environment variables to be set before command execution. They are
      expected to be in the form `ENV_VAR_NAME=value`. You can use this multiple times
      for setting multiple variables.\
      """,
      keep: true,
      alias: :e
    ]
  ]

  @options_schema Workspace.Cli.options(
                    [
                      :workspace_path,
                      :config_path,
                      :project,
                      :ignore,
                      :affected,
                      :modified,
                      :verbose,
                      :show_status
                    ],
                    @task_options
                  )

  @shortdoc "Run a mix command to all projects"

  @moduledoc """
  Run a mix task on one or more workspace projects

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """

  use Mix.Task

  import Workspace.Cli

  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts, args: args, extra: extra, invalid: invalid} = opts

    task_args = CliOpts.to_list(invalid) ++ extra ++ args

    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    workspace = Workspace.new!(workspace_path, config_path)

    workspace
    |> Workspace.filter(opts)
    |> maybe_include_status(opts[:show_status])
    |> Workspace.projects()
    |> Enum.map(fn project -> run_in_project(project, opts, task_args) end)
    |> raise_if_any_task_failed()
  end

  defp maybe_include_status(workspace, false), do: workspace
  defp maybe_include_status(workspace, true), do: Workspace.update_projects_statuses(workspace)

  defp run_in_project(%{skip: true, app: app}, args, _argv) do
    if args[:verbose] do
      log([
        highlight("#{args[:task]}", [:bright, :yellow]),
        "skipping #{app}"
      ])
    end
  end

  defp run_in_project(project, options, argv) do
    task = options[:task]

    task_args = [task | argv]

    env = parse_environment_variables(options[:env_var] || [])

    log_with_title(
      project_name(project, show_status: options[:show_status]),
      highlight("mix #{Enum.join(task_args, " ")}", :bright)
    )

    if not options[:dry_run] do
      run_task(project, task, argv, options, env)
    end
  end

  defp parse_environment_variables(vars) do
    Enum.map(vars, &parse_environment_variable/1)
  end

  defp parse_environment_variable(var) do
    case String.split(var, "=") do
      [name, value] when value != "" ->
        {String.upcase(name) |> String.to_charlist(), String.to_charlist(value)}

      other ->
        Mix.raise(
          "invalid environment variable definition, it should be of the form " <>
            "ENV_VAR_NAME=value, got: #{other}"
        )
    end
  end

  defp run_task(project, task, argv, options, env) do
    case options[:execution_mode] do
      "process" ->
        cmd(task, argv, project, env)

      "in-project" ->
        Mix.Project.in_project(
          project.app,
          project.path,
          fn _mixfile ->
            Mix.Task.run(task, argv)
          end
        )

      other ->
        Mix.raise(
          "invalid execution mode #{other}, only `process` and `in-project` are supported"
        )
    end
  end

  defp cmd(task, argv, project, env) do
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
        cd: project.path,
        env: env
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

        Mix.shell().info([
          highlight(inspect(project.app), [:bright, :red]),
          " ",
          highlight(task, :bright),
          " failed with ",
          highlight("#{status}", [:bright, :light_red])
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
