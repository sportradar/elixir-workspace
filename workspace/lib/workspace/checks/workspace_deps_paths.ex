defmodule Workspace.Checks.WorkspaceDepsPaths do
  @moduledoc """
  Checks that the relative paths of workspace dependencies are valid.

  Since workspace supports arbitraty nested paths, it is a common operation to
  move around workspace projects. This sanity check will validate that all relative
  paths are valid without having to compile the whole workspace.

  ## Example

  In order to enable the check add the following to your `.workspace.exs`

  ```elixir
  [
    module: Workspace.Checks.WorkspaceDepsPaths,
    description: "validate workspace relative path dependencies"
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def check(workspace, check) do
    Workspace.Check.check_projects(workspace, check, fn project ->
      validate_workspace_deps_paths(project, workspace)
    end)
  end

  defp validate_workspace_deps_paths(project, workspace) do
    workspace_deps = workspace_deps(project.config[:deps], workspace)

    invalid_paths =
      workspace_deps
      |> Enum.map(fn {app, path} -> {app, path, expected_path(project, workspace, app)} end)
      |> Enum.reject(fn {_app, path, expected} -> sanitize(path) == expected end)

    case invalid_paths do
      [] -> {:ok, check_metadata([])}
      mismatches -> {:error, check_metadata(mismatches)}
    end
  end

  defp workspace_deps(deps, workspace) do
    deps
    |> Enum.filter(fn dep -> workspace_project?(dep, workspace) end)
    # TODO: this expects a keyword list, make it more robust in case it is an absolute version
    |> Enum.map(fn {app, opts} -> {app, opts[:path]} end)
  end

  defp expected_path(project, workspace, app) do
    project_path = project.path
    dependency_path = Workspace.project!(workspace, app).path

    Workspace.Utils.Path.relative_to(dependency_path, project_path)
  end

  defp sanitize(path) do
    path |> Path.split() |> Path.join()
  end

  defp workspace_project?(dep, workspace) do
    app = elem(dep, 0)

    Workspace.project?(workspace, app)
  end

  defp check_metadata(mismatches) do
    [
      mismatches: mismatches
    ]
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    main_line = [
      "path mismatches for the following dependencies: "
    ]

    details =
      meta[:mismatches]
      |> Enum.map(fn {app, path, expected} ->
        [
          "\n",
          "    → ",
          :yellow,
          inspect(app),
          :reset,
          " expected ",
          :light_cyan,
          inspect(expected),
          :reset,
          " got ",
          :light_cyan,
          inspect(path),
          :reset
        ]
      end)

    Enum.concat([main_line | details])
  end

  def format_result(%Workspace.Check.Result{status: :ok}) do
    ["all workspace dependencies have a valid path"]
  end
end
