defmodule Workspace.Status do
  @moduledoc """
  Utilities related to the workspace status.

  The workspace status is defined by the changed files and the
  dependencies between the projects. A workspace project can
  have one of the following states:

  * `:modified` - if any of the project's files has been modified
  * `:affected` - if any of the project's dependencies is modified
  * `:unaffected` - if the project and any of it's dependencies have
  not been modified.

  > #### Git repository {: .info}
  >
  > Notice that it is assumed that `git` is used for the version
  > control of the repository. In any other case the workspace
  > status related functionality will not work.
  """

  @type file_info :: {Path.t(), Workspace.Git.change_type()}

  @doc """
  Annotates the workspace projects with their statuses.

  This will mark the workspace projects with either `:affected` or
  `:modified` based on the changes between the `:base` and `:head`
  references.

  ## Options

    * `:base` (`String.t()`) - The base git reference for detecting changed files,
    if not set only working tree changes will be included.
    * `:head` (`String.t()`) - The head git reference for detecting changed files. It
    is used only if `:base` is set.
    * `:force` (`boolean()`) - If set the workspace status will be force updated.
  """
  @spec update(workspace :: Workspace.State.t(), opts :: keyword()) :: Workspace.State.t()
  def update(workspace, opts \\ []) do
    case should_update_status?(workspace, opts[:force]) do
      false ->
        workspace

      true ->
        changes = changed(workspace, opts)

        modifications = Enum.filter(changes, fn {project, _changes} -> project != nil end)

        # Mark modified projects
        projects =
          Enum.reduce(modifications, workspace.projects, fn {project, changes}, projects ->
            Map.update!(projects, project, fn project ->
              Workspace.Project.modified(project, changes)
            end)
          end)

        # Check for projects affected by their affected_by paths
        affected_by_changes = check_affected_by_paths(workspace, changes)

        # Affected projects (from dependencies + affected_by paths)
        modified = Enum.map(modifications, fn {project, _changes} -> project end)

        affected_by_modified =
          Enum.map(affected_by_changes, fn {project, _changes} -> project end)

        affected = Workspace.Graph.affected(workspace, modified ++ affected_by_modified)

        projects =
          Enum.reduce(affected, projects, fn project, workspace_projects ->
            Map.update!(workspace_projects, project, fn project ->
              Workspace.Project.affected(project)
            end)
          end)

        workspace
        |> Workspace.State.set_projects(projects)
        |> Workspace.State.status_updated()
    end
  end

  defp should_update_status?(_workspace, true), do: true

  defp should_update_status?(workspace, _force),
    do: not Workspace.State.status_updated?(workspace)

  @doc """
  Returns the changed files grouped by the project they belong to.

  ## Options

    * `:base` (`String.t()`) - The base git reference for detecting changed files,
    if not set only working tree changes will be included.
    * `:head` (`String.t()`) - The head git reference for detecting changed files. It
    is used only if `:base` is set.
  """
  @spec changed(workspace :: Workspace.State.t(), opts :: keyword()) :: %{atom() => file_info()}
  def changed(workspace, opts \\ []) do
    # if the workspace has a git root then this is our starting point in order
    # to get relative paths with respect to the root. This way we can afterwards
    # create proper absolute paths since some git status commands only return relative files wrt
    # the current directory
    # if there is no git root then we use the workspace path as the root
    base_path = workspace.git_root_path || workspace.workspace_path

    case Workspace.Git.changed(
           cd: base_path,
           base: opts[:base],
           head: opts[:head]
         ) do
      {:ok, changed_files} ->
        changed_files
        |> Enum.map(fn {file, type} ->
          full_path = Path.join(workspace.git_root_path, file) |> Path.expand()

          parent_project =
            case Workspace.Topology.parent_project(workspace, full_path) do
              nil -> nil
              project -> project.app
            end

          {parent_project, {file, type}}
        end)
        |> Enum.group_by(fn {project, _file_info} -> project end, fn {_project, file_info} ->
          file_info
        end)

      {:error, reason} ->
        raise ArgumentError, "failed to get changed files: #{reason}"
    end
  end

  @doc """
  Returns the modified projects

  A workspace project is considered modified if any of it's files has
  changed with respect to the `base` branch.

  ## Options

    * `:base` (`String.t()`) - The base git reference for detecting changed files,
    if not set only working tree changes will be included.
    * `:head` (`String.t()`) - The head git reference for detecting changed files. It
    is used only if `:base` is set.
  """
  @spec modified(workspace :: Workspace.State.t(), opts :: keyword()) :: [atom()]
  def modified(workspace, opts \\ []) do
    workspace = update(workspace, opts)

    workspace.projects
    |> Enum.filter(fn {_name, project} -> Workspace.Project.modified?(project) end)
    |> Enum.map(fn {name, _project} -> name end)
    |> Enum.sort()
  end

  @doc """
  Returns the affected projects

  A project is considered affected if it has changed or any of it's children has
  changed.

  ## Options

    * `:base` (`String.t()`) - The base git reference for detecting changed files,
    if not set only working tree changes will be included.
    * `:head` (`String.t()`) - The head git reference for detecting changed files. It
    is used only if `:base` is set.
  """
  @spec affected(workspace :: Workspace.State.t(), opts :: keyword()) :: [atom()]
  def affected(workspace, opts \\ []) do
    workspace = update(workspace, opts)

    workspace.projects
    |> Enum.filter(fn {_name, project} -> Workspace.Project.affected?(project) end)
    |> Enum.map(fn {name, _project} -> name end)
    |> Enum.sort()
  end

  defp check_affected_by_paths(workspace, changes) do
    base_path = workspace.git_root_path || workspace.workspace_path

    # Expand all changed files to full paths
    changed_files =
      changes
      |> Map.values()
      |> List.flatten()
      |> Enum.map(fn {changed_file, type} ->
        {Path.expand(changed_file, base_path), type}
      end)

    # Check each project's affected_by paths
    workspace.projects
    |> Enum.filter(fn {_name, project} -> length(project.affected_by) > 0 end)
    |> Enum.reduce(%{}, fn {name, project}, acc ->
      affected_files =
        project.affected_by
        |> Enum.filter(fn affected_path ->
          # affected_path is already expanded in project creation
          # Check if any changed file matches this affected_by path
          Enum.any?(changed_files, fn {full_changed_path, _type} ->
            matches_affected_by_path?(full_changed_path, affected_path)
          end)
        end)

      if length(affected_files) > 0 do
        # Create file_info entries for the affected files
        file_infos = Enum.map(affected_files, fn file -> {file, :modified} end)
        Map.put(acc, name, file_infos)
      else
        acc
      end
    end)
  end

  defp matches_affected_by_path?(changed_path, affected_path) do
    cond do
      Workspace.Utils.Path.parent_dir?(affected_path, changed_path) -> true
      changed_path in Path.wildcard(affected_path) -> true
      true -> false
    end
  end
end
