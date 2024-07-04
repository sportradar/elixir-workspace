defmodule Workspace.Export do
  @moduledoc """
  Helper utilities for exporting the workspace to various formats.
  """

  @compile {:no_warn_undefined, {Jason, :encode!, 2}}

  @doc """
  Returns a `json` representation of the key workspace properties.

  By default only the `workspace_path` and the `projects` are included.

  ## Options

  * `:sort` - if set to `true` projects will be sorted alphabetically. Defaults to
  `false`.
  * `:relative` - if paths will be relative or absolute. If set to `true` then
  `workspace_path` will be set to `"."`. Defaults to `false`.

  Notice that skipped projects are not included.
  """
  @spec to_json(workspace :: Workspace.State.t(), opts :: keyword()) :: String.t()
  def to_json(workspace, opts \\ []) do
    assert_jason!("to_json/1")

    opts = Keyword.validate!(opts, sort: false, relative: false)

    workspace_path =
      case opts[:relative] do
        true -> "."
        false -> workspace.workspace_path
      end

    %{
      workspace_path: workspace_path,
      projects:
        workspace.projects
        |> Enum.reject(fn {_name, project} -> project.skip end)
        |> Enum.map(fn {_name, project} ->
          Workspace.Project.to_map(project, relative: opts[:relative])
        end)
        |> maybe_sort(opts[:sort])
    }
    |> Jason.encode!(pretty: true)
  end

  @doc """
  Returns a `json` representation of the given run results.
  """
  @spec run_results_to_json(results :: [map()]) :: String.t()
  def run_results_to_json(results) do
    assert_jason!("run_results_to_json/1")

    results
    |> Enum.map(fn result ->
      Map.put(result, :project, Workspace.Project.to_map(result.project))
    end)
    |> Jason.encode!(pretty: true)
  end

  @doc false
  @spec assert_jason!(fn_name :: String.t()) :: :ok
  def assert_jason!(fn_name) do
    unless Code.ensure_loaded?(Jason) do
      raise RuntimeError, """
      #{fn_name} depends on the :jason package.

      You can install it by adding

          {:jason, "~> 1.4"}

      to your dependency list.
      """
    end

    :ok
  end

  defp maybe_sort(projects, true), do: Enum.sort_by(projects, & &1.app)
  defp maybe_sort(projects, _other), do: projects
end
