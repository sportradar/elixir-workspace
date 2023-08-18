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
         workspace <- maybe_include_status(workspace, opts) do
      workspace
    else
      {:error, reason} ->
        raise Mix.Error, "failed to load workspace from #{workspace_path}: #{reason}"
    end
  end

  defp maybe_include_status(workspace, opts) do
    case opts[:show_status] do
      true -> Workspace.update_projects_statuses(workspace, base: opts[:base], head: opts[:head])
      _ -> workspace
    end
  end
end
