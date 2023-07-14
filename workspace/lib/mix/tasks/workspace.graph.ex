defmodule Mix.Tasks.Workspace.Graph do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path,
                    :show_status
                  ])

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

    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    workspace_config = Keyword.get(opts, :workspace_config, ".workspace.exs")

    workspace =
      Workspace.new(workspace_path, workspace_config)
      |> maybe_include_status(opts[:show_status])

    print_tree(workspace, opts[:show_status])
  end

  defp maybe_include_status(workspace, false), do: workspace
  defp maybe_include_status(workspace, true), do: Workspace.update_projects_statuses(workspace)

  defp print_tree(workspace, show_status) do
    Workspace.Graph.with_digraph(workspace, fn graph ->
      callback = fn {node, _format} ->
        children =
          :digraph.out_neighbours(graph, node)
          |> Enum.map(fn node -> {node, nil} end)
          |> Enum.sort()

        project = Map.fetch!(workspace.projects, node)

        {{node_format(project, show_status), nil}, children}
      end

      root_nodes =
        graph
        |> :digraph.source_vertices()
        |> Enum.map(fn node -> {node, nil} end)
        |> Enum.sort()

      Mix.Utils.print_tree(root_nodes, callback)
    end)

    :ok
  end

  defp node_format(project, false), do: inspect(project.app)

  defp node_format(project, true) do
    format_ansi([
      status_style(project.status),
      inspect(project.app),
      :reset,
      status_suffix(project.status)
    ])
  end

  defp status_style(:affected), do: [:yellow]
  defp status_style(:modified), do: [:bright, :red]
  defp status_style(_other), do: []

  defp status_suffix(:modified), do: [:bright, :red, " ✚", :reset]
  defp status_suffix(:affected), do: [:bright, :yellow, " ●", :reset]
  defp status_suffix(_other), do: [:bright, :green, " ✔", :reset]

  def format_ansi(message) do
    IO.ANSI.format(message) |> :erlang.iolist_to_binary()
  end
end
