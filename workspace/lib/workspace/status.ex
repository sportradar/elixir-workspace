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

        # Reset any previous status, since the update may be forced
        projects = Map.new(workspace.projects, fn {name, project} -> {name, reset(project)} end)

        # Mark modified projects
        projects =
          Enum.reduce(modifications, projects, fn {project, changes}, projects ->
            Map.update!(projects, project, fn project ->
              Workspace.Project.modified(project, changes)
            end)
          end)

        # Match the changed files against the affected_by paths of the graph
        path_changes = match_paths(workspace, changes)

        projects =
          Map.new(projects, fn {name, project} ->
            affected_by_changes =
              project.affected_by
              |> Enum.filter(&Map.has_key?(path_changes, &1))
              |> Enum.map(fn path -> {path, path_changes[path]} end)

            {name, Workspace.Project.set_affected_by_changes(project, affected_by_changes)}
          end)

        # Affected projects (from dependencies + affected_by paths)
        modified = Enum.map(modifications, fn {project, _changes} -> project end)

        affected =
          Workspace.Graph.affected(workspace, modified, paths: Map.keys(path_changes))

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

  @doc """
  Returns the `:affected_by` paths with at least one changed file.

  The paths are returned expanded, as defined in the projects' `:affected_by`.

  ## Options

    * `:base` (`String.t()`) - The base git reference for detecting changed files,
    if not set only working tree changes will be included.
    * `:head` (`String.t()`) - The head git reference for detecting changed files. It
    is used only if `:base` is set.
  """
  @spec changed_paths(workspace :: Workspace.State.t(), opts :: keyword()) :: [String.t()]
  def changed_paths(workspace, opts \\ []) do
    workspace = update(workspace, opts)

    workspace.projects
    |> Map.values()
    |> Enum.flat_map(fn project -> project.affected_by_changes || [] end)
    |> Enum.map(fn {path, _files} -> path end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp reset(project) do
    %{Workspace.Project.set_status(project, :undefined) | changes: nil, affected_by_changes: nil}
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
          full_path = Workspace.State.git_file_path(workspace, file)

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

  # Returns a map with the changed files of each affected_by path, paths
  # without any changed file are not included
  defp match_paths(workspace, changes) do
    changed_files =
      changes
      |> Map.values()
      |> List.flatten()
      |> Enum.map(fn {file, _type} = file_info ->
        {Workspace.State.git_file_path(workspace, file), file_info}
      end)

    # a path shared by many projects is matched once, the declaring project's
    # path is matched literally since it may contain wildcard characters
    workspace.projects
    |> Map.values()
    |> Enum.flat_map(fn project -> Enum.map(project.affected_by, &{&1, project.path}) end)
    |> Enum.uniq_by(fn {path, _project_path} -> path end)
    |> Enum.map(fn {path, project_path} ->
      regex = Workspace.Utils.Path.glob_to_regex(path, project_path)

      files =
        changed_files
        |> Enum.filter(fn {full_path, _file_info} -> Regex.match?(regex, full_path) end)
        |> Enum.map(fn {_full_path, file_info} -> file_info end)

      {path, files}
    end)
    |> Enum.reject(fn {_path, files} -> files == [] end)
    |> Map.new()
  end
end
