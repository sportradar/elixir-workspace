defmodule Workspace.Helpers do
  @moduledoc false

  # helper utility functions used throughout workspace

  @doc false
  @spec ensure_file_exists(path :: binary()) :: {:ok, binary()} | {:error, binary()}
  def ensure_file_exists(path) do
    case File.exists?(path) do
      true -> {:ok, path}
      false -> {:error, "file #{path} does not exist"}
    end
  end
end
