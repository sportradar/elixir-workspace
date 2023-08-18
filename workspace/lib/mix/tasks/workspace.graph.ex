defmodule Mix.Tasks.Workspace.Graph do
  @task_options [
    format: [
      type: :string,
      default: "pretty",
      doc: """
      The output format of the graph. It can be one of the following:
        * `pretty` - pretty prints the graph as a tree
        * `mermaid` - exports the graph as a mermaid graph

      """,
      allowed: ["pretty", "mermaid"]
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

  #{CliOpts.docs(@options_schema)}
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts} = opts

    workspace = Mix.WorkspaceUtils.load_and_filter_workspace(opts)

    case opts[:format] do
      "pretty" ->
        print_tree(workspace, show_status: opts[:show_status], external: opts[:external])

      "mermaid" ->
        mermaid_graph(workspace, show_status: opts[:show_status], external: opts[:external])
    end
  end

  defp print_tree(workspace, opts) do
    Workspace.Graph.with_digraph(
      workspace,
      fn graph ->
        callback = fn {node, _format} ->
          children =
            :digraph.out_neighbours(graph, node)
            |> Enum.map(fn node -> {node, nil} end)
            |> Enum.sort()

          {app, type} = node

          case type do
            :workspace ->
              project = Map.fetch!(workspace.projects, app)

              {{node_format(project, opts[:show_status]), nil}, children}

            :external ->
              display = format_ansi([:light_black, inspect(app), " (external)", :reset])
              {{display, nil}, children}
          end
        end

        root_nodes =
          graph
          |> :digraph.source_vertices()
          |> Enum.map(fn node -> {node, nil} end)
          |> Enum.sort()

        Mix.Utils.print_tree(root_nodes, callback)
      end,
      external: opts[:external]
    )

    :ok
  end

  defp node_format(project, show_status) do
    Workspace.Cli.project_name(project, show_status: show_status, default_style: :gray)
    |> Workspace.Cli.format()
    |> format_ansi()
  end

  def format_ansi(message) do
    IO.ANSI.format(message) |> :erlang.iolist_to_binary()
  end

  defp mermaid_graph(workspace, opts) do
    Workspace.Graph.with_digraph(
      workspace,
      fn graph ->
        vertices =
          :digraph.vertices(graph)
          |> Enum.map(fn {v, _type} -> "  #{v}" end)
          |> Enum.sort()
          |> Enum.join("\n")

        external =
          :digraph.vertices(graph)
          |> Enum.filter(fn {_v, type} -> type == :external end)
          |> Enum.map(fn {v, _type} -> v end)

        edges =
          :digraph.edges(graph)
          |> Enum.map(fn edge ->
            {_e, v1, v2, _l} = :digraph.edge(graph, edge)
            {v1, v2}
          end)
          |> Enum.map(fn {{v1, _type1}, {v2, _type2}} -> "  #{v1} --> #{v2}" end)
          |> Enum.sort()
          |> Enum.join("\n")

        """
        flowchart TD
        #{vertices}

        #{edges}
        #{external_node_format(external)}
        #{maybe_mermaid_node_format(workspace, opts[:show_status])}
        """
        |> String.trim()
        |> IO.puts()
      end,
      external: opts[:external]
    )
  end

  defp external_node_format(external) do
    external_styles = Enum.map_join(external, "\n", fn app -> "  class #{app} external;" end)

    [external_styles, "  classDef external fill:#999,color:#ee0;"]
    |> Enum.join("\n")
  end

  defp maybe_mermaid_node_format(_worksapce, false), do: ""

  defp maybe_mermaid_node_format(workspace, true) do
    node_styles =
      Workspace.projects(workspace)
      |> Enum.filter(fn project -> project.status in [:modified, :affected] end)
      |> Enum.map_join("\n", fn project -> "  class #{project.app} #{project.status};" end)

    """

    #{node_styles}

      classDef affected fill:#FA6,color:#FFF;
      classDef modified fill:#F33,color:#FFF;
    """
  end
end
