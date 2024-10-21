defmodule Mix.WorkspaceUtils do
  @moduledoc false

  # helper functions for workspace mix tasks since we use
  # common cli arguments

  @doc false
  @spec load_and_filter_workspace(opts :: keyword()) :: Workspace.State.t()
  def load_and_filter_workspace(opts) do
    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    Workspace.new!(workspace_path, config_path)
    |> Workspace.Filtering.run(opts)
    |> maybe_include_status(opts)
  end

  defp maybe_include_status(workspace, opts) do
    case opts[:show_status] do
      true ->
        validate_git_repo!(workspace)
        Workspace.Status.update(workspace, base: opts[:base], head: opts[:head])

      _ ->
        workspace
    end
  end

  defp validate_git_repo!(workspace) do
    case Workspace.Git.root(cd: workspace.workspace_path) do
      {:ok, _path} ->
        :ok

      {:error, _reason} ->
        path = Path.relative_to(workspace.workspace_path, File.cwd!(), force: true)

        Mix.raise("status related operations require a git repo, #{path} is not a valid git repo")
    end
  end
end
