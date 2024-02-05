defmodule Workspace.Status do
  @moduledoc """
  Utilities related to the workspace status.

  The workspace status is defined by the changed files and the
  dependencies between the projects. A workspace project can
  have one of the following states:

  * `:modified` - if any of the project's files has been modified
  * `:affected` - if any of the project's dependencies is modified
  * `:unaffected` - if the project and any of it's dependencis have
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
  """
  @spec update(workspace :: Workspace.State.t(), opts :: keyword()) :: Workspace.State.t()
  def update(workspace, opts) do
    changes = changed(workspace, opts)
    modified = modified_projects(changes)
    affected = affected_projects(workspace, modified)

    # we must first check the affected since the modified may update the
    # status
    projects =
      Enum.reduce(
        annotate(affected, :affected) ++ annotate(modified, :modified),
        workspace.projects,
        fn {app, status}, projects ->
          Map.update!(projects, app, fn project ->
            Workspace.Project.set_status(project, status)
          end)
        end
      )

    Workspace.State.set_projects(workspace, projects)
  end

  defp annotate(projects, annotation),
    do: Enum.map(projects, fn project -> {project, annotation} end)

  @doc """
  Returns the changed files grouped by the project they belong to.

  ## Options

    * `:base` (`String.t()`) - The base git reference for detecting changed files,
    if not set only working tree changes will be included.
    * `:head` (`String.t()`) - The head git reference for detecting changed files. It
    is used only if `:base` is set.
  """
  @spec changed(workspace :: Workspace.State.t(), opts :: keyword()) :: [{atom(), file_info()}]
  def changed(workspace, opts \\ []) do
    case Workspace.Git.changed_files(
           cd: workspace.workspace_path,
           base: opts[:base],
           head: opts[:head]
         ) do
      {:ok, changed_files} ->
        changed_files
        |> Enum.map(fn {file, type} ->
          full_path = Path.join(workspace.workspace_path, file) |> Path.expand()

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
    workspace
    |> changed(opts)
    |> modified_projects()
  end

  defp modified_projects(changes) do
    changes
    |> Enum.filter(fn {project, _changes} -> project != nil end)
    |> Enum.map(fn {project, _changes} -> project end)
    |> Enum.uniq()
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
    modified = modified(workspace, opts)
    affected_projects(workspace, modified)
  end

  defp affected_projects(workspace, modified), do: Workspace.Graph.affected(workspace, modified)
end
