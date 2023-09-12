defmodule Workspace.Coverage.Exporter do
  @moduledoc """
  The coverage exporter behaviour.
  """

  @doc """
  Export the given coverage data.

  TODO: add detailed docs
  """
  @callback export(workspace :: Workspace.t(), coverage_data :: [term()], opts :: keyword()) ::
              :ok | {:error, String.t()}
end
