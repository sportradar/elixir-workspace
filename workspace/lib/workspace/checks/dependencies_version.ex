defmodule Workspace.Checks.DependenciesVersion do
  hex_dep_tuple = {:or, [{:tuple, [:atom, :string]}, {:tuple, [:atom, :string, :keyword_list]}]}
  keyword_dep_tuple = {:tuple, [:atom, :keyword_list]}

  @schema NimbleOptions.new!(
            deps: [
              type: {:list, {:or, [hex_dep_tuple, keyword_dep_tuple]}},
              doc: "List of expected dependency versions",
              required: true
            ]
          )

  @moduledoc """
  Checks that the configured dependencies versions match the expected ones

  > #### Common use cases {: .tip}
  >
  > This check can be used in order to ensure common dependencies versions and
  > options across all projects of your mono-repo.

  ## Configuration

  #{NimbleOptions.docs(@schema)}

  ### Custom deps options

  Except the standard deps options supported by mix you can also set the
  following options which specify how the check will be applied on a
  dependency level:

  * `:no_options_check` - can either be a `boolean` or a list of atoms
  corresponding to projects. If set to `false` only the version and not the
  rest of the options will be checked. If set to a list the options will be
  checked for all projects except of those in the list.

  ## Example

  ```elixir
  [
    module: Workspace.Checks.DependenciesVersion,
    opts: [
      deps: [
        # checks both version and options
        {:ex_doc, "== 0.28.3", only: :dev, runtime: false}
        # checks only version for all projects
        {:ex_doc, "== 0.28.3", no_options_check: true}
        # checks only version for :foo, both version and options
        # for the other projects
        {:ex_doc, "== 0.28.3", only: :dev, runtime: false, no_options_check: [:foo]}
      ]
    ]
  ]
  ```
  """
  # TODO: handle path dependencies specially
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @check_deps_keys [:no_options_check]

  @impl Workspace.Check
  def check(workspace, check) do
    expected_deps =
      Keyword.fetch!(check[:opts], :deps)
      |> parse_deps()
      |> Enum.map(fn {dep, {version, opts}} ->
        {check_opts, opts} = Keyword.split(opts, @check_deps_keys)
        {dep, {version, opts, check_opts}}
      end)

    Workspace.Check.check_projects(workspace, check, fn project ->
      check_dependencies_versions(project, expected_deps)
    end)
  end

  defp check_dependencies_versions(project, expected_deps) do
    configured_deps = parse_deps(project.config[:deps])

    mismatches =
      configured_deps
      |> Enum.map(fn dep -> check_dependency_version(project.app, dep, expected_deps) end)
      |> Enum.filter(fn result ->
        case result do
          {:error, _dep} -> true
          :ok -> false
        end
      end)
      |> Enum.map(fn {:error, dep} -> dep end)

    case mismatches do
      [] -> {:ok, check_metadata(mismatches, configured_deps, expected_deps)}
      mismatches -> {:error, check_metadata(mismatches, configured_deps, expected_deps)}
    end
  end

  defp parse_deps(deps) do
    deps
    |> Enum.map(&split_dep_tuple/1)
    |> Enum.map(fn {dep, version, opts} -> {dep, {version, Enum.sort(opts)}} end)
  end

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

  defp check_dependency_version(app, {dep, {version, options}}, expected) do
    if Keyword.has_key?(expected, dep) do
      {expected_version, expected_options, check_opts} = expected[dep]

      cond do
        # if we have a version mismatch it is an error
        expected_version != version ->
          {:error, dep}

        # if no_options_check is set we are fine
        check_opts[:no_options_check] == true ->
          :ok

        # if no_options_check is set for this project we are fine
        app in Keyword.get(check_opts, :no_options_check, []) ->
          :ok

        # options must match if we haven't returned already
        expected_options != options ->
          {:error, dep}

        # in any other case we have a match
        true ->
          :ok
      end
    else
      :ok
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
          "    → ",
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
