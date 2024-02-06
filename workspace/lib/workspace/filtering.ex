defmodule Workspace.Filtering do
  @moduledoc """
  The workspace filtering logic.

  Most workspace tasks support various filtering methods, like
  excluding specific projects, including only projects with
  specific tags or with a specific modification status among other.

  This module provides all filtering related functionality.
  """

  @doc """
  Filter the `workspace` projects based on the given options.

  It will iterate over all projects and wil set the `:skip` to `true` if the
  project is considered skippable. The decision is made based on the passed
  options.

  A `Workspace.State` is returned with the projects statuses updated.

  ## Options

    * `:exclude` (list of `t:atom/0`) - a list of projects to be ignored. This has
    the highest priority, e.g. if the project is in the `:ignore` list it is
    always skipped.
    * `:project` (list of `t:atom/0`) - a list of project to consider, if set all
    projects that are not included in the list are considered skippable.
    * `:affected` (`t:boolean/0`) - if set only the affected projects will be
    included and everything else will be skipped. Defaults to `false`.
    * `:modified` (`t:boolean/0`) - if set only the modified projects will be
    included. A project is considered modified if any file under the project's
    root (excluding files in the `.gitignore`) has changed. Defaults to `false`.
    * `:only_roots` (`t:boolean/0`) - if set only the root projects will be
    included and everything else will be skipped. Defaults to `false`.
    * `:base` (`t:String.t/0`) - The base git reference for detecting changed files,
    If not set only working tree changes will be included.
    * `:head` (`t:String.t/0`) - The head git reference for detecting changed files.
    It is used only if `:base` is set.

  > #### Filtering order {: .neutral}
  > 
  > Notice that projects are filtered using the following precedence:
  >
  > * Ignored projects (`:exclude` option set)
  > * Selected projects (`:project` option set)
  > * Code status modifiers (`:affected`, `:modified` and `:only_roots`)
  """
  @spec run(workspace :: Workspace.State.t(), opts :: keyword()) :: Workspace.State.t()
  def run(%Workspace.State{} = workspace, opts) do
    projects = filter_projects(workspace, opts)

    Workspace.State.set_projects(workspace, projects)
  end

  defp filter_projects(workspace, opts) do
    ignored = Enum.map(opts[:exclude] || [], &maybe_to_atom/1)
    selected = Enum.map(opts[:project] || [], &maybe_to_atom/1)
    affected = opts[:affected] || false
    modified = opts[:modified] || false
    only_roots = opts[:only_roots] || false

    affected_projects =
      case affected do
        false -> nil
        true -> Workspace.Status.affected(workspace, base: opts[:base], head: opts[:head])
      end

    modified_projects =
      case modified do
        false -> nil
        true -> Workspace.Status.modified(workspace, base: opts[:base], head: opts[:head])
      end

    Enum.map(workspace.projects, fn {_name, project} ->
      Map.put(
        project,
        :skip,
        skippable?(project, selected, ignored, affected_projects, modified_projects, only_roots)
      )
    end)
  end

  defp skippable?(
         %Workspace.Project{app: app, root?: root?},
         selected,
         ignored,
         affected,
         modified,
         only_roots
       ) do
    cond do
      # first we check if the project is in the ignore list
      app in ignored ->
        true

      # next we check if the project is not selected
      selected != [] and app not in selected ->
        true

      # if only_roots is set and the project is not a root skip it
      only_roots and not root? ->
        true

      # next we check if affected is set and the project is not affected
      is_list(affected) and app not in affected ->
        true

      # next we check if modified is set and the project is not modified
      is_list(modified) and app not in modified ->
        true

      # in any other case it is not skippable
      true ->
        false
    end
  end

  defp maybe_to_atom(value) when is_atom(value), do: value
  defp maybe_to_atom(value) when is_binary(value), do: String.to_atom(value)
end
