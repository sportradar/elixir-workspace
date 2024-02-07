defmodule Workspace.CliOptions do
  @moduledoc false

  # add here options that are used in more than one mix task
  @default_cli_options [
    project: [
      type: :string,
      keep: true,
      alias: :p,
      doc:
        "The project name, can be defined multiple times. If not set all projects are considered"
    ],
    exclude: [
      type: :string,
      alias: :e,
      keep: true,
      doc: "Ignore the given projects"
    ],
    tag: [
      type: :string,
      keep: true,
      as: :tags,
      doc: """
      If set, only projects with the given tag(s) will be considered. For scoped tags you should
      provide a colon separated string (examples: `shared`, `scope:api`, `type:utils`). For
      excluding a specific tag use `--exclude-tag`
      """
    ],
    exclude_tag: [
      type: :string,
      keep: true,
      as: :excluded_tags,
      doc: """
      If set, any projects with any of the given tag(s) will be excluded. For scoped tags you should
      provide a colon separated string (examples: `shared`, `scope:api`, `type:utils`). For selecting
      a specific tag use `--tag`
      """
    ],
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
    verbose: [
      type: :boolean,
      doc: "If set enables verbose logging"
    ],
    workspace_path: [
      type: :string,
      doc: "If set it specifies the root workspace path, defaults to current directory"
    ],
    config_path: [
      type: :string,
      doc: "The path to the workspace config to be used, relative to the workspace path",
      default: ".workspace.exs"
    ],
    show_status: [
      type: :boolean,
      default: false,
      doc: "If set the status of each project will be included in the output graph"
    ],
    base: [
      type: :string,
      doc: """
      The base git reference to compare the head to. Applied only when `--affected` or `--modified`
      are set.
      """
    ],
    head: [
      type: :string,
      default: "HEAD",
      doc: """
      A reference to the git head. Applied only if `--base` is set for getting the changed files
      """
    ]
  ]

  @doc false
  @spec default_options() :: keyword()
  def default_options, do: @default_cli_options

  @doc false
  @spec option(key :: atom()) :: keyword()
  def option(key), do: Keyword.fetch!(@default_cli_options, key)
end
