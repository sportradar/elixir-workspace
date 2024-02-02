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
      keep: true
    ],
    allow_failure: [
      type: :string,
      doc: """
      Allow the task for this specific project to fail. Can be set more than once. 
      """,
      keep: true
    ]
  ]

  @options_schema Workspace.Cli.options(
                    [
                      :workspace_path,
                      :config_path,
                      :project,
                      :exclude,
                      :affected,
                      :modified,
                      :base,
                      :head,
                      :verbose,
                      :show_status
                    ],
                    @task_options
                  )

  @shortdoc "Run a mix command to all projects"

  @moduledoc """
  Run a mix task on one or more workspace projects.

  Monorepos can have hundreds of projects so being able to run a task against all
  or a subset of them is a key feature of `Workspace`.

  ## The project graph

  The core concept of `Workspace` is the project graph. This is a directed acyclic
  graphs depicting the internal project dependencies. This is used by all tasks
  internally in order to specify the status of the projects.

  Assume you have the following workspace:

  ```
  package_a
  ├── package_b ✚
  │   └── package_g
  ├── package_c
  │   ├── package_e
  │   └── package_f
  │       └── package_g
  └── package_d
  package_h ✚
  └── package_d
  ```

  It consists of various packages, and two of them (`_b` and `_h`) are modified. Using
  the graph we can find the dependencies between packages and **limit the execution of
  a task** only to the subset that makes sense. 

  **Using the proper execution strategy wisely significantly improves the CI execution
  time**.

  > #### Where to run a task? {: .tip}
  >
  > This clearly depends on the type of the task. Let's see some examples:
  >
  > - `mix format` makes sense to be executed only on the modified packages.
  > - `mix test` should be executed on the modified and the parents of them since a change
  > on a package may affect a dependent one.
  > - `mix deps.get` makes sense to be executed only on the root packages if
  > you have adopted a common deps path, since internal dependencies will be
  > inherited from dependent packages.
  > - In the main branch it makes sense to run the full suite on the
  > complete workspace.

  Check `Workspace` for more details. In order to visualize the graph of the current
  workspace check the `workspace.graph` task.

  ## Command-line Options

  #{CliOpts.docs(@options_schema, sort: true)}

  ## Filtering tasks

  One of the key features of `workspace.run` is the flexibility regarding the projects
  on which the task will be executed.

  Let's see some examples:

      # Run test on all workspace projects
      $ mix workspace.run -t test

      # Run test only on foo and bar
      $ mix workspace.run -t test -p foo -p bar

      # Run test on all projects excluding foo and bar
      $ mix workspace.run -t test --exclude foo --exclude bar

      # Run test on all affected projects
      $ mix workspace.run -t test --affected

      # Run test on all modified projects
      $ mix workspace.run -t test --modified

      # Run test only on top level projects
      $ mix workspace.run -t test --only-roots

  ## The `--env-var` option

  Some tasks depend on environment variables. You can use the `--env-var` option to
  set an environment variable only during a task's execution. This is particularly useful
  in CI environments.

      $ mix workspace.run -t compile --env-var MIX_ENV=compile

  You can set multiple environment variables by setting the `--env-var` multiple times.

  ## Dry running a task

  You can set the `--dry-run` option in order to dry run the task, e.g. to check the
  sequence of mix tasks that will be invoked.

  ## Allowing failures on some projects

  On big codebases not all projects are of the same quality standards and some linter
  tasks may fail on them. In such cases you may want to still run the linting tasks on
  these projects but ignore their output status from the overall run task's status. In
  such cases you can use the `--allow-failure` option:

      # Run lint on all projects but ignore the output status of project foo
      $ mix workspace.run -t lint --allow-failure foo
  """

  use Mix.Task

  @recursive true

  import Workspace.Cli

  @impl Mix.Task
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts, extra: extra} = opts

    opts =
      Keyword.update(opts, :allow_failure, [], fn projects ->
        Enum.map(projects, &String.to_atom/1)
      end)

    opts
    |> Mix.WorkspaceUtils.load_and_filter_workspace()
    |> Workspace.projects()
    |> Enum.map(fn project ->
      triggered_at = System.os_time(:millisecond)
      result = run_in_project(project, opts, extra)
      completed_at = System.os_time(:millisecond)

      %{
        project: project,
        status: execution_status(result, allowed_to_fail?(project.app, opts[:allow_failure])),
        triggered_at: triggered_at,
        completed_at: completed_at
      }
    end)
    |> raise_if_any_task_failed()
  end

  defp allowed_to_fail?(project, allowed_to_fail), do: project in allowed_to_fail

  defp execution_status({:error, _reason}, true), do: :warn
  defp execution_status({:error, _reason}, false), do: :error
  defp execution_status(_status, _allowed_to_fail), do: :ok

  defp run_in_project(%{skip: true} = project, options, _argv) do
    if options[:verbose] do
      log_with_title(
        project_name(project, show_status: options[:show_status]),
        highlight("skipped", [:bright, :yellow]),
        prefix: :header
      )
    end
  end

  defp run_in_project(project, options, argv) do
    task = options[:task]

    task_args = [task | argv]

    env = parse_environment_variables(options[:env_var] || [])

    log_with_title(
      project_name(project, show_status: options[:show_status]),
      highlight("mix #{Enum.join(task_args, " ")}", :bright),
      prefix: :header
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

        log([
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
    {_successful, warnings, failures} =
      Enum.reduce(
        task_results,
        {[], [], []},
        fn project, {successful, warnings, failures} ->
          case project[:status] do
            :error ->
              {successful, warnings, [project | failures]}

            :warn ->
              {successful, [project | warnings], failures}

            :ok ->
              {[project | successful], warnings, failures}
          end
        end
      )

    names = fn projects -> Enum.map(projects, & &1.project.app) end

    if length(warnings) > 0 do
      Workspace.Cli.log([
        :yellow,
        "WARNING ",
        :reset,
        "task failed in #{length(warnings)} projects but the ",
        :light_cyan,
        "--alow-failure",
        :reset,
        " flag is set"
      ])

      Workspace.Cli.log(["  failed projects - ", :yellow, inspect(names.(warnings))])
    end

    if length(failures) > 0 do
      Mix.raise("""
      mix workspace.run failed - errors detected in #{length(failures)} executions
      failed projects - #{inspect(names.(failures))}
      """)
    end
  end
end
