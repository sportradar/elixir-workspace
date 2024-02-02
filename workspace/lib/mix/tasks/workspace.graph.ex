defmodule Mix.Tasks.Workspace.Graph do
  @task_options [
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
                    @task_options
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
  alias Workspace.Graph.Formatters

  @impl Mix.Task
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts} = opts

    workspace = Mix.WorkspaceUtils.load_and_filter_workspace(opts)

    case opts[:format] do
      "pretty" ->
        Formatters.PrintTree.render(
          workspace,
          Keyword.take(opts, [:show_status, :external, :exclude])
          |> Keyword.merge(pretty: true)
        )

      "plain" ->
        Formatters.PrintTree.render(
          workspace,
          Keyword.take(opts, [:show_status, :external, :exclude])
          |> Keyword.merge(pretty: false)
        )

      "mermaid" ->
        Formatters.Mermaid.render(
          workspace,
          Keyword.take(opts, [:show_status, :external, :exclude])
        )
    end
  end
end
