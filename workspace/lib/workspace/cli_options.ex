defmodule Workspace.CliOptions do
  @moduledoc false

  # add here options that are used in more than one mix task
  @default_cli_options [
    project: [
      type: :string,
      multiple: true,
      short: "p",
      doc:
        "The project name, can be defined multiple times. If not set all projects are considered",
      doc_section: :filtering
    ],
    exclude: [
      type: :string,
      short: "e",
      multiple: true,
      doc: "Ignore the given projects",
      doc_section: :filtering
    ],
    paths: [
      type: :string,
      multiple: true,
      long: "path",
      doc: """
      A path under which projects will be considered. Paths should be relative with respect to
      the workspace root. All other projects can be ignored. Can be set multiple times.
      """,
      doc_section: :filtering
    ],
    tags: [
      type: :string,
      multiple: true,
      long: "tag",
      doc: """
      If set, only projects with the given tag(s) will be considered. For scoped tags you should
      provide a colon separated string (examples: `shared`, `scope:api`, `type:utils`). For
      excluding a specific tag use `--exclude-tag`
      """,
      doc_section: :filtering
    ],
    dependency: [
      type: :string,
      multiple: false,
      doc: """
      If set, only projects that have the given dependency will be considered.
      """,
      doc_section: :filtering
    ],
    dependent: [
      type: :string,
      multiple: false,
      doc: """
      If set, only projects that are dependencies of the given project are considered.
      """,
      doc_section: :filtering
    ],
    excluded_tags: [
      type: :string,
      multiple: true,
      long: "exclude-tag",
      doc: """
      If set, any projects with any of the given tag(s) will be excluded. For scoped tags you should
      provide a colon separated string (examples: `shared`, `scope:api`, `type:utils`). For selecting
      a specific tag use `--tag`
      """,
      doc_section: :filtering
    ],
    affected: [
      type: :boolean,
      short: "a",
      doc: "Run only on affected projects",
      doc_section: :status
    ],
    modified: [
      type: :boolean,
      short: "m",
      doc: "Run only on modified projects",
      doc_section: :status
    ],
    verbose: [
      type: :boolean,
      doc: "If set enables verbose logging",
      doc_section: :display
    ],
    workspace_path: [
      type: :string,
      doc: "If set it specifies the root workspace path, defaults to current directory",
      doc_section: :workspace
    ],
    config_path: [
      type: :string,
      doc: "The path to the workspace config to be used, relative to the workspace path",
      default: ".workspace.exs",
      doc_section: :workspace
    ],
    show_status: [
      type: :boolean,
      default: false,
      doc: "If set the status of each project will be included in the output graph",
      doc_section: :display
    ],
    base: [
      type: :string,
      doc: """
      The base git reference to compare the head to. Applied only when `--affected` or `--modified`
      are set.
      """,
      doc_section: :status
    ],
    head: [
      type: :string,
      default: "HEAD",
      doc: """
      A reference to the git head. Applied only if `--base` is set for getting the changed files
      """,
      doc_section: :status
    ]
  ]

  @doc false
  @spec default_options() :: keyword()
  def default_options, do: @default_cli_options

  @doc false
  @spec option(key :: atom()) :: keyword()
  def option(key), do: Keyword.fetch!(@default_cli_options, key)

  @doc false
  @spec doc_sections() :: keyword()
  def doc_sections do
    [
      status: [
        header: "Workspace status options",
        doc: """
        Status is retrieved from the diff between the given `--base` and `--head`. Knowing the
        changed files we can limit the execution of workspace commands only to relevant projects.
        """
      ],
      filtering: [
        header: "Filtering options"
      ],
      display: [
        header: "Display options"
      ],
      export: [
        header: "Export options"
      ],
      workspace: [
        header: "Global workspace options"
      ]
    ]
  end
end
