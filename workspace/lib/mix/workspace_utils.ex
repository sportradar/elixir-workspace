defmodule Mix.WorkspaceUtils do
  @moduledoc false

  # helper functions for workspace mix tasks since we use
  # common cli arguments

  @doc false
  def load_and_filter_workspace(opts) do
    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    Workspace.new!(workspace_path, config_path)
    |> Workspace.Filtering.run(opts)
    |> maybe_include_status(opts)
  end

  defp maybe_include_status(workspace, opts) do
    case opts[:show_status] do
      true -> Workspace.Status.update(workspace, base: opts[:base], head: opts[:head])
      _ -> workspace
    end
  end
end
