defmodule Workspace.CliOptions do
  @moduledoc false

  # add here options that are used in more than one mix task
  @default_cli_options [
    affected: [
      type: :boolean,
      alias: :a,
      doc: "Run only on affected projects"
    ],
    modified: [
      type: :boolean,
      alias: :m,
      doc: "Run only on modified projects"
    ],
    ignore: [
      type: :string,
      alias: :i,
      keep: true,
      doc: "Ignore the given projects"
    ],
    task: [
      type: :string,
      alias: :t,
      doc: "The task to execute",
      required: true
    ],
    execution_order: [
      type: :string,
      default: "serial",
      doc: "The execution order, one of `serial`, `parallel`, `roots`, `bottom-up`"
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
    verbose: [
      type: :boolean,
      doc: "If set enables verbose logging"
    ],
    workspace_path: [
      type: :string,
      doc: "If set it specifies the root workspace path, defaults to current directory."
    ],
    config_path: [
      type: :string,
      doc: "The path to the workspace config to be used, relative to the workspace path",
      default: ".workspace.exs"
    ],
    project: [
      type: :string,
      keep: true,
      alias: :p,
      doc:
        "The project name, can be defined multiple times. If not set all projects are considered."
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
    ],
    show_status: [
      type: :boolean,
      default: false,
      doc: "If set the status of each project will be included in the output graph"
    ]
  ]

  @doc false
  @spec default_options() :: keyword()
  def default_options, do: @default_cli_options

  @doc false
  @spec option(key :: atom()) :: keyword()
  def option(key), do: Keyword.fetch!(@default_cli_options, key)
end
