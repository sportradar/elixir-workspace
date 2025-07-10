defmodule Workspace.List.Formatter do
  @moduledoc """
  A behaviour for defining custom formatters for using with `mix workspace.list`.

  A formatter is responsible for visualizing the workspace list.
  """

  @typedoc "A module implementing the `Workspace.List.Formatter` behaviour."
  @type formatter :: module()

  @doc """
  Formats the given workspace using the provided `formatter` and options.

  ## Options
  """

  @spec format(formatter :: formatter(), workspace :: Workspace.State.t(), opts :: keyword()) ::
  :ok
  def format(formatter, workspace, opts) do
    formatter.render(workspace, opts)
  end

  @doc """
  Renders the given workspace list.

  The formatter is responsible for printing any console output or generating any
  output file, based on the given `opts`.

  Options are arbitrary and any formatter can support custom options.
  """
  @callback render(workspace :: Workspace.State.t(), opts :: keyword()) ::
  :ok
end
