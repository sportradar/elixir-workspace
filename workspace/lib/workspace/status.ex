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
    case Workspace.Git.changed_files(
           cd: workspace.workspace_path,
           base: opts[:base],
           head: opts[:head]
         ) do
      {:ok, changed_files} ->
        changed_files
        |> Enum.map(fn {file, _type} ->
          Path.join(workspace.workspace_path, file) |> Path.expand()
        end)
        |> Enum.map(fn file -> Workspace.Topology.parent_project(workspace, file) end)
        |> Enum.filter(fn project -> project != nil end)
        |> Enum.map(& &1.app)
        |> Enum.uniq()

      {:error, reason} ->
        raise ArgumentError, "failed to get modified files: #{reason}"
    end
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
