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
  """

  @type file_info :: {Path.t(), Workspace.Git.change_type()}

  @doc """
  Returns the changed files grouped by the project they belong to.

  ## Options

    * `:base` (`String.t()`) - The base git reference for detecting changed files,
    if not set only working tree changes will be included.
    * `:head` (`String.t()`) - The head git reference for detecting changed files. It
    is used only if `:base` is set.
  """
  @spec changed(workspace :: Workspace.t(), opts :: keyword()) :: [{atom(), file_info()}]
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
  @spec modified(workspace :: Workspace.t(), opts :: keyword()) :: [atom()]
  def modified(workspace, opts \\ []) do
    changed(workspace, opts)
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
  @spec affected(workspace :: Workspace.t(), opts :: keyword()) :: [atom()]
  def affected(workspace, opts \\ []) do
    modified = modified(workspace, opts)

    Workspace.Graph.affected(workspace, modified)
  end
end
