defmodule Workspace.Checks.DependenciesVersion do
  @moduledoc """
  Checks that the configured dependencies versions match the expected ones

  This check can be used in order to ensure common dependencies versions and
  options across all projects of your mono-repo.

  ## Configuration

  It expects the following configuration parameters:

  * `:deps` - a list of expected dependencies tuples. 

  ## Example

  # TODO: fix it
  In order to configure this checker add the following, under `checkers`,
  in your `workspace.exs`:

  ```elixir
  [
    module: Workspace.Checks.EnsureDependencies,
    opts: [
      deps: [:ex_doc, :credo]
    ]
  ]
  ```
  """
  # TODO: add a strict option for matching both options and version
  # TODO: handle path dependencies specially
  # TODO: return multiple lines with detailed mismatch info if verbose is set
  # TODO: sort keyword lists before checking
  # TODO: deps_to_keyword -> sort keyword
  @behaviour Workspace.Check

  @impl Workspace.Check
  def check(workspace, check) do
    deps =
      Keyword.fetch!(check[:opts], :deps)
      |> deps_to_keyword()

    Workspace.Check.check_projects(workspace, check, fn project ->
      check_dependencies_versions(project, deps)
    end)
  end

  defp check_dependencies_versions(project, deps) do
    configured_deps = deps_to_keyword(project.config[:deps])

    mismatches =
      configured_deps
      |> Enum.filter(fn {dep, options} -> dep_mismatch?(dep, options, deps) end)
      |> Enum.map(&elem(&1, 0))

    case mismatches do
      [] -> {:ok, check_metadata(mismatches, configured_deps, deps)}
      mismatches -> {:error, check_metadata(mismatches, configured_deps, deps)}
    end
  end

  defp deps_to_keyword(deps), do: Enum.map(deps, &split_dep_tuple/1)

  defp split_dep_tuple(dep) do
    dep_name = elem(dep, 0)
    rest = Tuple.delete_at(dep, 0)

    {dep_name, rest}
  end

  defp dep_mismatch?(dep, options, expected) do
    case Keyword.has_key?(expected, dep) do
      true -> expected[dep] != options
      false -> false
    end
  end

  defp check_metadata(mismatches, configured, expected) do
    [
      mismatches: mismatches,
      configured: Keyword.take(configured, mismatches),
      expected: Keyword.take(expected, mismatches)
    ]
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    [
      "version mismatches for the following dependencies: ",
      :light_cyan,
      inspect(meta[:mismatches]),
      :reset
    ]
  end

  def format_result(%Workspace.Check.Result{status: :ok}) do
    ["all dependencies versions match the expected ones"]
  end
end
