defmodule Mix.Tasks.Workspace.Run do
  opts = [
    task: [
      type: :string,
      short: "t",
      doc: "The task to execute",
      required: true
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
    env_vars: [
      type: :string,
      doc: """
      Optional environment variables to be set before command execution. They are
      expected to be in the form `ENV_VAR_NAME=value`. You can use this multiple times
      for setting multiple variables.\
      """,
      long: "env-var",
      multiple: true
    ],
    allow_failure: [
      type: :atom,
      doc: """
      Allow the task for this specific project to fail. Can be set more than once. 
      """,
      multiple: true
    ],
    early_stop: [
      type: :boolean,
      doc: """
      If set the execution will stop if the execution of any project failed
      """,
      default: false
    ],
    partitions: [
      type: :integer,
      doc: """
      Sets the number of partitions to split executions in. It must be a number
      greater than zero. If set to `1` it acts as a no-op. If more than one you
      must also set the the `WORKSPACE_RUN_PARTITION` environment variable with
      the partition to use in the current execution. See the "Run partitioning"
      section for more details
      """
    ]
  ]

  @options_schema Workspace.Cli.options(
                    [
                      :workspace_path,
                      :config_path,
                      :project,
                      :exclude,
                      :tags,
                      :excluded_tags,
                      :affected,
                      :modified,
                      :base,
                      :head,
                      :verbose,
                      :show_status
                    ],
                    opts
                  )

  @shortdoc "Run a mix command to all projects"

  @moduledoc """
  Run a mix task on one or more workspace projects.

  You need to specify the task to be executed with the `--task, -t` option:

      $ mix workspace.run -t format

  This will run `mix format` on all projects of the workspace. You can also select
  the projects to run, or exclude specific projects:

      # Run format only on foo and bar
      $ mix workspace.run -t format -p foo -p bar

      # Run format on all projects except foo
      $ mix workspace.run -t format -e foo

  ### Passing options to tasks

  You can pass task specific options after the return separator (`--`). For example:

      $ mix workspace.run -t format -p foo -p bar -- --check-formatted
      
  ## Command-line Options

  #{CliOptions.docs(@options_schema, sort: true)}

  ## Filtering runs

  Monorepos can have hundreds of projects so being able to run a task against all
  or a subset of them is a key feature of Workspace.

  One of the key features of `workspace.run` is the flexibility regarding the projects
  on which the task will be executed.

  ### The project graph

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

  In order to visualize the graph of the current workspace check the `mix workspace.graph`
  task.

  ### Filtering examples

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

  ## Run partitioning

  In big workspaces some CI steps may take a lot time. You can split the execution of
  a task in multiple partitions in order to speed up this process. This is done by
  setting the `--partitions` option and setting the `WORKSPACE_RUN_PARTITION` environment
  variable to control the current partition.

  For example to split the execution of `mix test` on all workspace projects into
  4 partitions, you would use the following:

      $ WORKSPACE_RUN_PARTITION=1 mix workspace.run -t run --partitions 4
      $ WORKSPACE_RUN_PARTITION=2 mix workspace.run -t run --partitions 4
      $ WORKSPACE_RUN_PARTITION=3 mix workspace.run -t run --partitions 4
      $ WORKSPACE_RUN_PARTITION=4 mix workspace.run -t run --partitions 4

  The matching projects are sorted upfront and assigned to each partition in a round-robin
  fashion.

  ## The `--env-var` option

  Some tasks depend on environment variables. You can use the `--env-var` option to
  set an environment variable only during a task's execution. This is particularly useful
  in CI environments.

      $ mix workspace.run -t compile --env-var MIX_ENV=compile

  You can set multiple environment variables by setting the `--env-var` multiple times.

  ## Early stopping

  You can set the `--early-stop` flag in order to immediately terminate the command if
  the execution in any of the projects has failed.

  ## Allowing failures on some projects

  On big codebases not all projects are of the same quality standards and some linter
  tasks may fail on them. In such cases you may want to still run the linting tasks on
  these projects but ignore their output status from the overall run task's status. In
  such cases you can use the `--allow-failure` option:

      # Run lint on all projects but ignore the output status of project foo
      $ mix workspace.run -t lint --allow-failure foo

  ## Dry running a task

  You can set the `--dry-run` option in order to dry run the task, e.g. to check the
  sequence of mix tasks that will be invoked.
  """

  use Mix.Task

  @recursive true

  import Workspace.Cli

  @impl Mix.Task
  def run(args) do
    Mix.Task.reenable("workspace.run")

    {opts, _args, extra} = CliOptions.parse!(args, @options_schema)

    env = Enum.map(opts[:env_vars] || [], &parse_environment_variable/1)

    opts =
      opts
      |> Keyword.put(:env, env)
      |> Keyword.put(:argv, extra)
      |> Keyword.put_new(:allow_failure, [])

    result =
      opts
      |> Mix.WorkspaceUtils.load_and_filter_workspace()
      |> Workspace.projects()
      |> filter_by_partition(opts[:partitions])
      |> Enum.map(fn project ->
        triggered_at = System.os_time(:millisecond)
        result = run_task(project, opts)
        completed_at = System.os_time(:millisecond)

        execution_result =
          %{
            project: project,
            task: opts[:task],
            argv: opts[:argv],
            status: execution_status(result, allowed_to_fail?(project.app, opts[:allow_failure])),
            status_code: status_code(result),
            triggered_at: triggered_at,
            completed_at: completed_at
          }

        log_task_execution_result(execution_result)

        if opts[:early_stop] do
          maybe_early_stop(execution_result)
        end

        execution_result
      end)
      |> Enum.group_by(fn result -> result.status end)

    maybe_log_warnings(result[:warn] || [])
    raise_if_errors(result[:error] || [])
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

  defp filter_by_partition(projects, partitions) when partitions in [nil, 1], do: projects

  defp filter_by_partition(projects, partitions) when partitions > 1 do
    partition = System.get_env("WORKSPACE_RUN_PARTITION")

    case partition && Integer.parse(partition) do
      {partition, ""} when partition in 1..partitions ->
        partition = partition - 1

        for {project, index} <- Enum.with_index(Enum.sort_by(projects, & &1.app)),
            rem(index, partitions) == partition,
            do: project

      _other ->
        Mix.raise(
          "The WORKSPACE_RUN_PARTITION environment variable must be set to an integer between " <>
            "1..#{partitions} when the --partitions option is set, got: #{inspect(partition)}"
        )
    end
  end

  # if the project is skipped we only print a message if --verbose is set
  defp run_task(%{skip: true} = project, options) do
    if options[:verbose] do
      log_with_title(
        project_name(project, show_status: options[:show_status]),
        highlight("skipped", [:bright, :yellow]),
        prefix: :header
      )
    end

    :skip
  end

  defp run_task(project, options) do
    log_with_title(
      project_name(project, show_status: options[:show_status]),
      highlight(mix_task_to_string(options[:task], options[:argv]), :bright),
      prefix: :header
    )

    case options[:dry_run] do
      true -> :skip
      false -> cmd(options[:task], options[:argv], project, options[:env])
    end
  end

  defp mix_task_to_string(task, argv), do: ~s'mix #{Enum.join([task | argv], " ")}'

  defp cmd(task, argv, project, env) do
    [command | args] = enable_ansi(["mix", task | argv])

    command = System.find_executable(command)

    status_code =
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
      |> stream_output()

    case status_code do
      0 -> :ok
      status_code -> {:error, status_code}
    end
  end

  # elixir tasks are not run in a TTY and will by default not print ANSI
  # characters, We explicitely enable ANSI
  # kudos to `ex_check`: https://github.com/karolsluszniak/ex_check
  defp enable_ansi(["mix" | args]) do
    erl_config = Application.app_dir(:workspace, ~w[priv enable_ansi.config])

    ["elixir", "--erl-config", erl_config, "-S", "mix" | args]
  end

  defp stream_output(port) do
    receive do
      {^port, {:data, data}} ->
        IO.write(data)
        stream_output(port)

      {^port, {:exit_status, status}} ->
        status
    end
  end

  defp allowed_to_fail?(project, allowed_to_fail), do: project in allowed_to_fail

  defp execution_status({:error, _status}, true), do: :warn
  defp execution_status({:error, _status}, false), do: :error
  defp execution_status(status, _allowed_to_fail), do: status

  defp status_code({:error, status}), do: status
  defp status_code(:skip), do: nil
  defp status_code(:ok), do: 0

  defp maybe_early_stop(result) do
    case result[:status] do
      :error ->
        Mix.raise("--early-stop is set - terminating workspace.run")

      _other ->
        result
    end
  end

  defp log_task_execution_result(%{status: status} = result) when status in [:error, :warn] do
    log([
      highlight(inspect(result.project.app), [:bright, :red]),
      " ",
      highlight(mix_task_to_string(result.task, result.argv), :bright),
      " failed with ",
      highlight("#{result.status_code}", [:bright, :light_red])
    ])
  end

  defp log_task_execution_result(_result), do: :ok

  defp maybe_log_warnings(projects) do
    if length(projects) > 0 do
      names = Enum.map(projects, & &1.project.app)

      Workspace.Cli.log([
        :yellow,
        "WARNING ",
        :reset,
        "task failed in #{length(projects)} projects but the ",
        :light_cyan,
        "--alow-failure",
        :reset,
        " flag is set"
      ])

      Workspace.Cli.log(["  failed projects - ", :yellow, inspect(names)])
    end
  end

  defp raise_if_errors(projects) do
    names = Enum.map(projects, & &1.project.app)

    if length(projects) > 0 do
      Mix.raise("""
      mix workspace.run failed - errors detected in #{length(names)} executions
      failed projects - #{inspect(names)}
      """)
    end
  end
end
