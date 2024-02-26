defmodule Workspace.Graph.Formatter do
  @moduledoc """
  A behaviour for defining custom formatters for using with `mix workspace.graph`.

  A formatter is responsible for visualizing the workpsace graph.
  """

  @typedoc "A module implementing the `Workspace.Graph.Formatter` behaviour."
  @type formatter :: module()

  @doc """
  Formats the given workspace using the provided `formatter` and options.

  ## Options
  """
  @spec format(formatter :: formatter(), workspace :: Workspace.State.t(), opts :: keyword()) ::
          :ok
  def format(formatter, workspace, opts) do
    Workspace.Graph.with_digraph(
      workspace,
      fn graph ->
        case opts[:focus] do
          nil ->
            formatter.render(graph, workspace, opts)

          project ->
            proximity = Keyword.fetch!(opts, :proximity)
            subgraph = Workspace.Graph.subgraph(graph, String.to_atom(project), proximity)

            formatter.render(subgraph, workspace, opts)
        end
      end,
      external: opts[:external],
      exclude: opts[:exclude]
    )
  end

  @doc """
  Renders the given workspace graph.

  The formatter is responsible for printing any console output or generating any
  output file, based on the given `opts`.

  The `graph` is expected to be the `:digraph.graph()` to be printed. The graph may
  be a subgraph of the full workspace graph.

  Options are arbitrary and any formatter can support custom options.
  """
  @callback render(graph :: :digraph.graph(), workspace :: Workspace.State.t(), opts :: keyword()) ::
              :ok
end
