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
  project is considered skippable. The decision is made based on the provided
  options.

  A `Workspace.State` is returned with the projects updated.

  ## Options

    * `:exclude` (list of `t:atom/0`) - a list of projects to be ignored. This has
    the highest priority, e.g. if the project is in the `:ignore` list it is
    always skipped.
    * `:exclude_tags` (list of `t:Workspace.Project.tag()`) - a list of tags to be
    ignored. Any project that has any of the provided tags will be skipped.
    * `:project` (list of `t:atom/0`) - a list of projects to consider. If set all
    projects that are not included in the list are considered skippable.
    * `:tags` (list of `t:Workspace.Project.tag()`) - a list of tags to be
    considered. All projects that do not have at least one the specified tags will
    be skipped.
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
  > * Excluded projects (`:exclude` or `:exclude_tags` options set)
  > * Selected projects (`:project` or `:tags` option set)
  > * Code status modifiers (`:affected`, `:modified` and `:only_roots`)
  """
  @spec run(workspace :: Workspace.State.t(), opts :: keyword()) :: Workspace.State.t()
  def run(%Workspace.State{} = workspace, opts) do
    workspace =
      maybe_update_status(
        workspace,
        Keyword.take(opts, [:base, :head]),
        opts[:affected] || opts[:modified]
      )

    projects = filter_projects(workspace, opts)

    Workspace.State.set_projects(workspace, projects)
  end

  defp maybe_update_status(workspace, opts, true), do: Workspace.Status.update(workspace, opts)
  defp maybe_update_status(workspace, _opts, _other), do: workspace

  defp filter_projects(workspace, opts) do
    opts = [
      excluded: Enum.map(opts[:exclude] || [], &maybe_to_atom/1),
      selected: Enum.map(opts[:project] || [], &maybe_to_atom/1),
      affected: opts[:affected] || false,
      modified: opts[:modified] || false,
      only_roots: opts[:only_roots] || false
    ]

    Enum.map(workspace.projects, fn {_name, project} ->
      Map.put(project, :skip, skippable?(project, opts))
    end)
  end

  defp maybe_to_atom(value) when is_atom(value), do: value
  defp maybe_to_atom(value) when is_binary(value), do: String.to_atom(value)

  defp skippable?(project, opts) do
    excluded_project?(project, opts[:excluded]) or
      not_selected_project?(project, opts[:selected]) or
      not_root?(project, opts[:only_roots]) or
      not_affected?(project, opts[:affected]) or
      not_modified?(project, opts[:modified])
  end

  defp excluded_project?(project, excluded), do: project.app in excluded

  defp not_selected_project?(_project, []), do: false
  defp not_selected_project?(project, selected), do: project.app not in selected

  defp not_root?(_project, false), do: false
  defp not_root?(project, true), do: not project.root?

  defp not_affected?(_project, false), do: false
  defp not_affected?(project, true), do: not Workspace.Project.affected?(project)

  defp not_modified?(_project, false), do: false
  defp not_modified?(project, true), do: not Workspace.Project.modified?(project)
end
