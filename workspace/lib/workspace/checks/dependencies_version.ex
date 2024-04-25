defmodule Workspace.Checks.DependenciesVersion do
  dependencies_schema = [
    *: [
      type: :keyword_list,
      keys: [
        version: [
          type: {:or, [:string, :non_empty_keyword_list]},
          type_doc: "`t:String.t/0` or `t:Keyword.t/0`",
          doc: """
          The required version of the package. This can either be a string indicating
          hex version numbers or a keyword list for git or path dependencies.
          """,
          required: true
        ],
        options: [
          type: :keyword_list,
          doc: """
          Other options of the dependencies definition that should also match. This is
          useful in case you to ensure for example that specific dependencies are loaded
          only in the `:dev` environment. In order to do this, you have to set the `:options`
          to `[only: :test]`.

          If not set only the version will be checked.
          """
        ]
      ]
    ]
  ]

  @schema NimbleOptions.new!(
            deps: [
              type: :non_empty_keyword_list,
              doc: """
              Defines the required dependencies versions across the workspace. Each key
              corresponds to the name of an external dependency, and the value should be
              a keyword list which accepts the following options:
              """,
              keys: dependencies_schema
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

  ## Example

  ```elixir
  [
    module: Workspace.Checks.DependenciesVersion,
    opts: [
      deps: [
        # checks version and :only and :runtime options
        ex_doc: [
          version: "== 0.28.3",
          options: [:only, :runtime]
        ],
        # checks only version
        ex_doc: [
          version: "== 0.28.3",
        ],
        # checks a git dependency version
        ex_doc: [
          version: [github: "elixir-lang/ex_doc"]
        ]
      ]
    ]
  ]
  ```
  """
  # TODO: handle path dependencies specially
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @impl Workspace.Check
  def check(workspace, check) do
    expected_deps = Keyword.fetch!(check[:opts], :deps)

    Workspace.Check.check_projects(workspace, check, fn project ->
      check_dependencies_versions(project, expected_deps)
    end)
  end

  defp check_dependencies_versions(project, expected_deps) do
    project_deps = Enum.map(project.config[:deps], &split_dep_tuple/1)

    mismatches =
      project_deps
      |> Enum.map(fn dep -> check_dependency_version(project.app, dep, expected_deps) end)
      |> Enum.filter(fn result ->
        case result do
          {:error, _dep} -> true
          :ok -> false
        end
      end)
      |> Enum.map(fn {:error, dep} -> dep end)

    case mismatches do
      [] -> {:ok, check_metadata(mismatches, project_deps, expected_deps)}
      mismatches -> {:error, check_metadata(mismatches, project_deps, expected_deps)}
    end
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
        {version_opts, rest_opts} = Keyword.split(opts, [:git, :path, :github, :branch])

        {dep_name, version_opts, rest_opts}
    end
  end

  defp check_dependency_version(_app, {dep, version, options}, expected) do
    if Keyword.has_key?(expected, dep) do
      with true <- check_versions_match(version, expected[dep]),
           true <- maybe_check_options_match(options, expected[dep]) do
        :ok
      else
        false -> {:error, dep}
      end
    else
      :ok
    end
  end

  defp check_versions_match(version, expected) do
    expected_version = Keyword.fetch!(expected, :version)

    version == expected_version
  end

  defp maybe_check_options_match(options, expected) do
    case expected[:options] do
      nil ->
        true

      expected_options ->
        expected_options == options
    end
  end

  defp check_metadata(mismatches, configured, expected) do
    [
      mismatches: mismatches,
      configured: Enum.map(configured, fn {name, version, opts} -> {name, {version, opts}} end),
      expected: expected
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
