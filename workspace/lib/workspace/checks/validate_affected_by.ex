defmodule Workspace.Checks.ValidateAffectedBy do
  @moduledoc """
  Checks that the `:affected_by` paths of the projects are valid

  A path declared in a project's `:affected_by` config is considered invalid if:

    * it does not match any file of the repository, e.g. due to a typo or a
    renamed directory. In this case changes that should affect the project would
    silently be ignored.
    * it is within the project's own path. Changes of the project's files already
    mark it as modified, so such a path has no effect.

  Only the files known to `git` are considered, e.g. tracked files and untracked
  files that are not ignored. Paths are matched exactly as during the workspace
  status update, so this check requires the workspace to be in a git repository.

  Notice that paths within other workspace projects are valid, since a project
  may depend on files of another project without a mix dependency between them.

  ## Example

  In order to configure this check add the following, under `checks`,
  in your `.workspace.exs`:

  ```elixir
  [
    module: Workspace.Checks.ValidateAffectedBy,
    description: "all affected_by paths must be valid"
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def check(workspace, check) do
    files = repo_files(workspace)

    Workspace.Check.check_projects(workspace, check, fn project ->
      validate_affected_by(project, files)
    end)
  end

  defp repo_files(%Workspace.State{git_root_path: nil}), do: nil

  defp repo_files(workspace) do
    case Workspace.Git.files(cd: workspace.git_root_path) do
      {:ok, files} -> Enum.map(files, &Path.expand(&1, workspace.git_root_path))
      {:error, _reason} -> nil
    end
  end

  defp validate_affected_by(%Workspace.Project{affected_by: []}, _files), do: {:ok, []}

  defp validate_affected_by(_project, nil), do: {:error, no_git_repo: true}

  defp validate_affected_by(project, files) do
    invalid =
      project.affected_by
      |> Enum.map(fn path -> {path, invalid_reason(project, path, files)} end)
      |> Enum.reject(fn {_path, reason} -> is_nil(reason) end)

    case invalid do
      [] -> {:ok, paths: project.affected_by}
      invalid -> {:error, invalid: invalid}
    end
  end

  defp invalid_reason(project, path, files) do
    regex = Workspace.Utils.Path.glob_to_regex(path)

    cond do
      Workspace.Utils.Path.parent_dir?(project.path, path) -> :within_project
      not Enum.any?(files, &Regex.match?(regex, &1)) -> :no_matching_files
      true -> nil
    end
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{status: :error, meta: meta, project: project}) do
    case meta[:no_git_repo] do
      true ->
        ["cannot validate :affected_by paths, the workspace is not in a git repository"]

      _other ->
        details =
          Enum.map(meta[:invalid], fn {path, reason} ->
            ["\n", :light_cyan, relative_path(path, project), :reset, " ", reason(reason)]
          end)

        ["invalid :affected_by paths" | details]
    end
  end

  def format_result(%Workspace.Check.Result{status: :ok, meta: meta, project: project}) do
    case meta[:paths] do
      nil ->
        ["no :affected_by paths set"]

      paths ->
        paths = Enum.map_join(paths, ", ", &relative_path(&1, project))
        ["all :affected_by paths are valid: ", :light_cyan, paths]
    end
  end

  defp relative_path(path, project), do: Path.relative_to(path, project.path, force: true)

  defp reason(:within_project), do: "is within the project's path"
  defp reason(:no_matching_files), do: "does not match any file"
end
