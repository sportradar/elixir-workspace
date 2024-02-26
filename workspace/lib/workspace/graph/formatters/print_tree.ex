defmodule Workspace.Graph.Formatters.PrintTree do
  @moduledoc false
  @behaviour Workspace.Graph.Formatter

  @doc """
  Renders a workspace graph as text.

  ## Options

  * `:pretty` - if not set only ascii characters will be used
  * `:show_status` - if set the status of the package will be included
  * `:show_tags` - if set the tags of the package will be displayed
  """
  @impl true
  def render(graph, workspace, opts) do
    pretty = Keyword.fetch!(opts, :pretty)

    callback = fn {node, _format} ->
      children =
        :digraph.out_neighbours(graph, node)
        |> Enum.map(fn node -> {node, nil} end)
        |> Enum.sort()

      case node.type do
        :workspace ->
          project = Workspace.project!(workspace, node.app)

          {{node_format(project, opts[:show_status], opts[:show_tags]), nil}, children}

        :external ->
          display = format_ansi([:light_black, inspect(node.app), " (external)", :reset])
          {{display, nil}, children}
      end
    end

    root_nodes =
      graph
      |> :digraph.source_vertices()
      |> Enum.map(fn node -> {node, nil} end)
      |> Enum.sort()

    print_tree(root_nodes, callback, pretty: pretty)
  end

  defp node_format(project, show_status, show_tags) do
    Workspace.Cli.project_name(project, show_status: show_status, default_style: :gray)
    |> maybe_add_tags(project.tags, show_tags)
    |> Workspace.Cli.format()
    |> format_ansi()
  end

  defp maybe_add_tags(name, [], _show_tags), do: name

  defp maybe_add_tags(name, tags, true) do
    tags =
      Enum.map(tags, fn tag -> [:tag, Workspace.Project.format_tag(tag), :reset] end)
      |> Enum.intersperse(", ")

    [name, " " | tags]
  end

  defp maybe_add_tags(name, _tags, _show_tags), do: name

  defp format_ansi(message) do
    IO.ANSI.format(message) |> :erlang.iolist_to_binary()
  end

  # The following is copied from Mix.Utils

  @type formatted_node :: {name :: String.Chars.t(), edge_info :: String.Chars.t()}

  defp print_tree(nodes, callback, opts) do
    pretty = Keyword.fetch!(opts, :pretty)

    print_tree(nodes, _depth = [], _seen = %{}, pretty, callback)
    :ok
  end

  defp print_tree(nodes, depth, seen, pretty?, callback) do
    # We perform a breadth first traversal so we always show a dependency
    # a node with its children as high as possible in tree. This helps avoid
    # very deep trees.
    {nodes, seen} =
      Enum.flat_map_reduce(nodes, seen, fn node, seen ->
        {{name, info}, children} = callback.(node)

        if Map.has_key?(seen, name) do
          {[{name, info, []}], seen}
        else
          {[{name, info, children}], Map.put(seen, name, true)}
        end
      end)

    print_each_node(nodes, depth, seen, pretty?, callback)
  end

  defp print_each_node([], _depth, seen, _pretty?, _callback) do
    seen
  end

  defp print_each_node([{name, info, children} | nodes], depth, seen, pretty?, callback) do
    info = if(info, do: " #{info}", else: "")
    Mix.shell().info("#{depth(pretty?, depth)}#{prefix(pretty?, depth, nodes)}#{name}#{info}")

    seen = print_tree(children, [nodes != [] | depth], seen, pretty?, callback)
    print_each_node(nodes, depth, seen, pretty?, callback)
  end

  defp depth(_pretty?, []), do: ""
  defp depth(pretty?, depth), do: Enum.reverse(depth) |> tl |> Enum.map(&entry(pretty?, &1))

  defp entry(false, true), do: "|   "
  defp entry(false, false), do: "    "
  defp entry(true, true), do: "│   "
  defp entry(true, false), do: "    "

  defp prefix(false, [], _), do: ""
  defp prefix(false, _, []), do: "`-- "
  defp prefix(false, _, _), do: "|-- "
  defp prefix(true, [], _), do: ""
  defp prefix(true, _, []), do: "└── "
  defp prefix(true, _, _), do: "├── "
end
