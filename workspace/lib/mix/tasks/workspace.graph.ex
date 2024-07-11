defmodule Mix.Tasks.Workspace.Graph do
  opts = [
    format: [
      type: :string,
      default: "pretty",
      doc: """
      The output format of the graph. It can be one of the following:
        * `pretty` - pretty prints the graph as a tree.
        * `plain` - does not use Unicode code points for formatting the tree.
        * `mermaid` - exports the graph as a mermaid graph.
        * `dot` - produces a graphviz DOT graph description of the workspace.
      """,
      allowed: ["pretty", "plain", "mermaid", "dot"]
    ],
    external: [
      type: :boolean,
      default: false,
      doc: """
      If set external dependencies will also be inlcuded in the generated
      graph.
      """
    ],
    show_tags: [
      type: :boolean,
      default: false,
      doc: """
      If set the project's tags are also included in the generated graph. Currently
      applicable only for `:pretty` and `:plain` formatters.
      """,
      doc_section: :display
    ],
    focus: [
      type: :string,
      doc: """
      If set the graph will be focused around the given project. Should be combined
      with `:proximity` in order to define the depth of inward and outward neighbours
      to be displayed.
      """
    ],
    proximity: [
      type: :integer,
      default: 1,
      doc: """
      The maximum allowed proximity between a graph's project and children or parent
      projects. Only applicable if `:focus` is set.
      """
    ]
  ]

  @options_schema Workspace.Cli.options(
                    [
                      :workspace_path,
                      :config_path,
                      :show_status,
                      :exclude,
                      :base,
                      :head
                    ],
                    opts
                  )

  @shortdoc "Prints the dependency tree"

  @moduledoc """
  Prints the workspace graph.

      $ mix workspace.graph

  ## Formatters

  By default the graph will be pretty printed in the terminal:

      $ mix workspace.graph
      :api
      ├── :accounts
      │   └── :ecto_utils
      ├── :cli_tools
      └── :orders
          ├── :string_utils
          └── :warehouse
              └── :ecto_utils
      :back_office
      └── :cli_tools

  You can also format it as `mermaid` or `dot`:

      $ mix workspace.graph --format dot
      digraph G {
        accounts -> ecto_utils;
        api -> accounts;
        api -> cli_tools;
        api -> orders;
        back_office -> cli_tools;
        orders -> string_utils;
        orders -> warehouse;
        warehouse -> ecto_utils;
      }

  ## Showing project's statuses

  If you pass the `--show-status` flag the project statuses are also
  included.

      $ mix workspace.graph --show-status
      :api ✚
      ├── :accounts ✔
      │   └── :ecto_utils ✔
      ├── :cli_tools ✚
      └── :orders ✔
          ├── :string_utils ✔
          └── :warehouse ✔
              └── :ecto_utils ✔
      :back_office ●
      └── :cli_tools ✚

  The following color coding is used:

  * Modified projects are shown in **red color**
  * Affected projects are shown in **orange color**

  ## Focusing the graph around a project

  You can focus the graph around a single project by passing the `--focus`
  option.

      $ mix workspace.graph --focus api
      :api
      ├── :accounts
      ├── :cli_tools
      └── :orders

  This will print the graph around `cli_tools` including only it's children
  and parents that have a distance of 1 edge from it. You can widen the
  picture by setting the `--proximity` flag.

  ## External dependencies

  By default only the workspace projects are included in the graph. You
  can however include the external dependencies by passing the `--external`
  flag:

      $ mix workspace.graph --external
      :api
      ├── :accounts
      │   └── :ecto_utils
      │       └── :poison (external)
      ├── :cli_tools
      └── :orders
          ├── :string_utils
          │   └── :ex_doc (external)
          └── :warehouse
              └── :ecto_utils
      :back_office
      └── :cli_tools

  ## Command Line Options

  #{CliOptions.docs(@options_schema, sort: true, sections: Workspace.CliOptions.doc_sections())}
  """
  use Mix.Task
  alias Workspace.Graph.Formatter
  alias Workspace.Graph.Formatters

  @impl Mix.Task
  def run(args) do
    {opts, _args, _extra} = CliOptions.parse!(args, @options_schema)

    workspace = Mix.WorkspaceUtils.load_and_filter_workspace(opts)

    case opts[:format] do
      "pretty" ->
        Formatter.format(
          Formatters.PrintTree,
          workspace,
          Keyword.merge(opts, pretty: true)
        )

      "plain" ->
        Formatter.format(
          Formatters.PrintTree,
          workspace,
          Keyword.merge(opts, pretty: false)
        )

      "mermaid" ->
        Formatter.format(Formatters.Mermaid, workspace, opts)

      "dot" ->
        Formatter.format(Formatters.Dot, workspace, opts)
    end
  end
end
