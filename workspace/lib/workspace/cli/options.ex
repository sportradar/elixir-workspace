defmodule Workspace.Cli.Options do
  @moduledoc false

  @doc false
  @spec option(atom()) :: keyword()
  def option(:affected),
    do: [
      type: :boolean,
      alias: :a,
      doc: "Run only on affected projects"
    ]

  def option(:ignore),
    do: [
      type: :string,
      alias: :i,
      keep: true,
      doc: "Ignore the given projects"
    ]

  def option(:task),
    do: [
      type: :string,
      alias: :t,
      doc: "The task to execute",
      required: true
    ]

  def option(:execution_order),
    do: [
      type: :string,
      default: "serial",
      doc: "The execution order, one of `serial`, `parallel`, `roots`, `bottom-up`"
    ]

  def option(:execution_mode),
    do: [
      type: :string,
      default: "process",
      doc: """
      The execution mode. It supports the following values:

        - `process` - every subcommand will be executed as a different process, this
        is the preferred mode for most mix tasks
        - `subtask` - invokes `Mix.Task.run` from the workspace in the given project\
      """
    ]

  def option(:verbose),
    do: [
      type: :boolean,
      doc: "If set enables verbose logging"
    ]

  def option(:workspace_path),
    do: [
      type: :string,
      doc: "If set it specifies the root workspace path, defaults to current directory."
    ]

  def option(:config_path),
    do: [
      type: :string,
      doc: "The path to the workspace config to be used, relative to the workspace path",
      default: ".workspace.exs"
    ]

  def option(:project),
    do: [
      type: :string,
      keep: true,
      alias: :p,
      doc:
        "The project name, can be defined multiple times. If not set all projects are considered."
    ]

  def option(:dry_run),
    do: [
      type: :boolean,
      doc: "If set it will not execute the command, useful for testing and debugging.",
      default: false
    ]

  def option(:env_var),
    do: [
      type: :string,
      doc: """
      Optional environment variables to be set before command execution. They are
      expected to be in the form `ENV_VAR_NAME=value`. You can use this multiple times
      for setting multiple variables.\
      """,
      keep: true,
      alias: :e
    ]

  def option(invalid), do: raise(ArgumentError, "invalid option #{inspect(invalid)}")
end
