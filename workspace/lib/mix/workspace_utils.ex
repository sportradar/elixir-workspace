defmodule Mix.WorkspaceUtils do
  @moduledoc false

  # helper functions for workspace mix tasks since we use
  # common cli arguments

  @doc false
  def load_and_filter_workspace(opts) do
    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    with {:ok, workspace} <- Workspace.new(workspace_path, config_path),
         workspace <- Workspace.filter(workspace, opts),
         workspace <- maybe_include_status(workspace, opts[:show_status]) do
      workspace
    else
      {:error, reason} ->
        raise Mix.Error, "failed to load workspace from #{workspace_path}: #{reason}"
    end
  end

  defp maybe_include_status(workspace, false), do: workspace
  defp maybe_include_status(workspace, nil), do: workspace
  defp maybe_include_status(workspace, true), do: Workspace.update_projects_statuses(workspace)
end
