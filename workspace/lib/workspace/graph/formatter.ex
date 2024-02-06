defmodule Workspace.Graph.Formatter do
  @moduledoc """
  A behaviour for defining custom formatters for using with `mix workspace.graph`.

  A formatter is responsible for visualizing the workpsace graph.
  """

  @doc """
  Renders the given workspace.

  The formatter is responsible for printing any console output or generating any
  output file, based on the given `opts`.

  Options are generic and any formatter can support custom options.
  """
  @callback render(workspace :: Workspace.State.t(), opts :: keyword()) :: :ok
end
