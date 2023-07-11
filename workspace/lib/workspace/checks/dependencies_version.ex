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
    expected_deps =
      Keyword.fetch!(check[:opts], :deps)
      |> parse_deps()
      |> Enum.map(fn {dep, version, opts} -> {dep, {version, opts}} end)

    Workspace.Check.check_projects(workspace, check, fn project ->
      check_dependencies_versions(project, expected_deps)
    end)
  end

  defp check_dependencies_versions(project, expected_deps) do
    configured_deps = parse_deps(project.config[:deps])

    mismatches =
      configured_deps
      |> Enum.map(fn dep -> check_dependency_version(dep, expected_deps) end)
      |> Enum.filter(fn result ->
        case result do
          {:error, _dep, _message} -> true
          :ok -> false
        end
      end)
      |> Enum.map(fn {:error, dep, message} -> {dep, message} end)

    case mismatches do
      [] -> {:ok, check_metadata(mismatches, configured_deps, expected_deps)}
      mismatches -> {:error, check_metadata(mismatches, configured_deps, expected_deps)}
    end
  end

  defp parse_deps(deps), do: Enum.map(deps, &split_dep_tuple/1)

  defp split_dep_tuple(dep) do
    dep_name = elem(dep, 0)
    rest = Tuple.delete_at(dep, 0)

    case rest do
      {version, opts} when is_binary(version) and is_list(opts) ->
        {dep_name, version, opts}

      {version} when is_binary(version) ->
        {dep_name, version, []}

      {opts} when is_list(opts) ->
        {dep_name, nil, opts}
    end
  end

  defp check_dependency_version({dep, version, options}, expected) do
    if Keyword.has_key?(expected, dep) do
      {expected_version, expected_options} = expected[dep]

      cond do
        expected_version != version ->
          {:error, dep,
           "#{inspect(dep)} - expected version: #{expected_version}, got: #{version}"}

        expected_options != options ->
          {:error, dep,
           "#{inspect(dep)} - expected options: #{inspect(expected_options)}, got: #{inspect(options)}"}

        true ->
          :ok
      end
    else
      :ok
    end
  end

  defp check_metadata(mismatches, configured, expected) do
    mismatched_deps = Enum.map(mismatches, fn {dep, _message} -> dep end)
    configured = Enum.map(configured, fn {dep, version, opts} -> {dep, {version, opts}} end)

    [
      mismatches: mismatched_deps,
      configured: Keyword.take(configured, mismatched_deps),
      expected: Keyword.take(expected, mismatched_deps)
    ]
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    main_line = [
      "version mismatches for the following dependencies: ",
      :yellow,
      inspect(meta[:mismatches]),
      :reset
    ]

    details =
      meta[:mismatches]
      |> Enum.map(fn dep ->
        [
          "\n",
          "     ",
          :yellow,
          inspect(dep),
          :reset,
          " expected ",
          :light_cyan,
          inspect(meta[:expected][dep]),
          :reset,
          " got ",
          :light_cyan,
          inspect(meta[:configured][dep]),
          :reset
        ]
      end)

    Enum.concat([main_line | details])
  end

  def format_result(%Workspace.Check.Result{status: :ok}) do
    ["all dependencies versions match the expected ones"]
  end
end
