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
      """
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

  If no dependency is given, it uses the tree defined in the `mix.exs` file.

  ## Command Line Options

  #{CliOptions.docs(@options_schema, sort: true)}
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
