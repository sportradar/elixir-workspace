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
    * `:include` (list of `t:atom/0`) - a list of projects to always include. This
    acts as a union with the filtered results, adding back projects even if they
    were filtered out by other flags (except `:exclude` which has highest priority).
    * `:project` (list of `t:atom/0`) - a list of projects to consider. If set all
    projects that are not included in the list are considered skippable.
    * `:tags` (list of `t:Workspace.Project.tag()`) - a list of tags to be
    considered. All projects that do not have at least one the specified tags will
    be skipped.
    * `:paths` (list of `t:String.t()`) - a list of project paths to be considered.
    Only projects located under any of the provided path will be considered.
    * `:dependency` (`t:atom/0`) - keeps only projects that have the given dependency.
    * `:dependent` (`t:atom/0`) - keeps only dependencies of the given project.
    * `:recursive` (`t:boolean/0`) - if set, when used with `:dependency` or `:dependent`,
    it will consider all transitive dependencies instead of just first-level ones. Defaults to `false`.
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
  > * Included projects (`:include` option set) - added back as a union after all other filters
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
    filter_opts = [
      excluded: Enum.map(opts[:exclude] || [], &maybe_to_atom/1),
      selected: Enum.map(opts[:project] || [], &maybe_to_atom/1),
      affected: opts[:affected] || false,
      modified: opts[:modified] || false,
      only_roots: opts[:only_roots] || false,
      excluded_tags: opts[:excluded_tags] || [],
      tags: Enum.map(opts[:tags] || [], &maybe_to_tag/1),
      dependency: maybe_to_atom(opts[:dependency]),
      dependent: maybe_to_atom(opts[:dependent]),
      recursive: opts[:recursive] || false,
      paths: opts[:paths]
    ]

    included = Enum.map(opts[:include] || [], &maybe_to_atom/1)

    workspace.projects
    |> Enum.map(fn {_name, project} -> maybe_skip(workspace, project, filter_opts) end)
    |> maybe_include(included, filter_opts[:excluded])
  end

  # Un-skip projects in the include list, unless they're in the exclude list
  # (exclude has highest priority)
  defp maybe_include(projects, [], _excluded), do: projects

  defp maybe_include(projects, included, excluded) do
    Enum.map(projects, fn project ->
      if project.app in included and project.app not in excluded do
        Workspace.Project.unskip(project)
      else
        project
      end
    end)
  end

  defp maybe_to_atom(nil), do: nil
  defp maybe_to_atom(value) when is_atom(value), do: value
  defp maybe_to_atom(value) when is_binary(value), do: String.to_atom(value)

  defp maybe_to_tag(tag) when is_atom(tag), do: tag
  defp maybe_to_tag({scope, tag}) when is_atom(scope) and is_atom(tag), do: {scope, tag}

  defp maybe_to_tag(tag) when is_binary(tag) do
    case String.split(tag, ":") do
      [tag] ->
        String.to_atom(tag)

      [scope, tag] ->
        {String.to_atom(scope), String.to_atom(tag)}

      _other ->
        raise ArgumentError,
              "invalid tag, it should be `tag` or `scope:tag`, got: #{inspect(tag)}"
    end
  end

  defp maybe_to_tag(_other),
    do:
      raise(ArgumentError, "invalid tag, it should be a string of the form `tag` or `scope:tag`")

  defp maybe_skip(workspace, project, opts) do
    project
    |> skip_if(workspace, fn project, _workspace ->
      excluded_project?(project, opts[:excluded])
    end)
    |> skip_if(workspace, fn project, _workspace ->
      excluded_tag?(project, opts[:excluded_tags])
    end)
    |> skip_if(workspace, fn project, _workspace ->
      not_selected_project?(project, opts[:selected])
    end)
    |> skip_if(workspace, fn project, _workspace -> not_selected_tag?(project, opts[:tags]) end)
    |> skip_if(workspace, fn project, _workspace -> not_in_paths?(project, opts[:paths]) end)
    |> skip_if(workspace, fn project, _workspace -> not_root?(project, opts[:only_roots]) end)
    |> skip_if(workspace, fn project, _workspace -> not_affected?(project, opts[:affected]) end)
    |> skip_if(workspace, fn project, _workspace -> not_modified?(project, opts[:modified]) end)
    |> skip_if(workspace, fn project, workspace ->
      not_dependency?(workspace, project, opts[:dependency], opts[:recursive])
    end)
    |> skip_if(workspace, fn project, workspace ->
      not_dependent?(workspace, project, opts[:dependent], opts[:recursive])
    end)
  end

  # if the project is already skipped there is no reason to check again
  # otherwise we evaluate the condition and skip accordingly
  defp skip_if(%Workspace.Project{skip: true} = project, _workspace, _skip_condition), do: project

  defp skip_if(project, workspace, skip_condition) do
    if skip_condition.(project, workspace) do
      Workspace.Project.skip(project)
    else
      project
    end
  end

  defp excluded_project?(project, excluded), do: project.app in excluded

  defp excluded_tag?(project, excluded_tags),
    do: Enum.any?(project.tags, fn tag -> tag in excluded_tags end)

  defp not_selected_project?(_project, []), do: false
  defp not_selected_project?(project, selected), do: project.app not in selected

  defp not_selected_tag?(_project, []), do: false

  defp not_selected_tag?(project, tags),
    do: Enum.all?(project.tags, fn tag -> tag not in tags end)

  defp not_in_paths?(_project, nil), do: false

  defp not_in_paths?(project, paths) do
    Enum.all?(paths, fn path ->
      path = Path.join(project.workspace_path, path) |> Path.expand()

      not String.starts_with?(project.mix_path, path <> "/")
    end)
  end

  defp not_root?(_project, false), do: false
  defp not_root?(project, true), do: not project.root?

  defp not_affected?(_project, false), do: false
  defp not_affected?(project, true), do: not Workspace.Project.affected?(project)

  defp not_modified?(_project, false), do: false
  defp not_modified?(project, true), do: not Workspace.Project.modified?(project)

  defp not_dependency?(_workspace, _project, nil, _recursive), do: false

  defp not_dependency?(workspace, project, dependency, recursive) do
    deps =
      if recursive do
        Workspace.Graph.all_dependencies(workspace, project.app)
      else
        Workspace.Graph.dependencies(workspace, project.app)
      end

    dependency not in deps
  end

  defp not_dependent?(_workspace, _project, nil, _recursive), do: false

  defp not_dependent?(workspace, project, dependent, recursive) do
    deps =
      if recursive do
        Workspace.Graph.all_dependencies(workspace, dependent)
      else
        Workspace.Graph.dependencies(workspace, dependent)
      end

    project.app not in deps
  end
end
