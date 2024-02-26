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
      """,
      allowed: ["pretty", "plain", "mermaid"]
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

  #{CliOpts.docs(@options_schema, sort: true)}
  """
  use Mix.Task
  alias Workspace.Graph.Formatter
  alias Workspace.Graph.Formatters

  @impl Mix.Task
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts} = opts

    workspace = Mix.WorkspaceUtils.load_and_filter_workspace(opts)

    formatter_options = Keyword.take(opts, [:show_status, :show_tags, :external, :exclude])

    case opts[:format] do
      "pretty" ->
        Formatter.format(
          Formatters.PrintTree,
          workspace,
          Keyword.merge(formatter_options, pretty: true)
        )

      "plain" ->
        Formatter.format(
          Formatters.PrintTree,
          workspace,
          Keyword.merge(formatter_options, pretty: false)
        )

      "mermaid" ->
        Formatter.format(Formatters.Mermaid, workspace, formatter_options)
    end
  end
end
