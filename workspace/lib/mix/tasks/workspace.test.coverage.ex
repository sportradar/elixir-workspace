defmodule Mix.Tasks.Workspace.Test.Coverage do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path,
                    :project,
                    :affected,
                    :modified,
                    :ignore,
                    :verbose
                  ])

  @shortdoc "Runs test coverage on the workspace"

  @moduledoc """
  Run test coverage on the workspace

  You can use it to generate test coverage for one or more projects of the
  workspace. It will take care of finding the `coveradata` files, fixing the
  absolute paths with respect to the workspace root and formatting the
  resutls

      $ mix workspace.test.coverage

  ## Invocation requirements

  This task assumes that `mix test` has been executed with `--cover` and the
  `:export` option under `:test_coverage` set. It is advised to configure a
  workspace check that ensures that all projects have these options properly
  set.

  ```elixir
  [
    module: Workspace.Checks.ValidateConfig,
    description: "all projects must have test coverage export option set",
    opts: [
      validate: fn config ->
        coverage_opts = config[:test_coverage] || []
        case coverage_opts[:export] do
          nil -> {:error, "export option not defined under :test_coverage settings"}
          _value -> {:ok, ""}
        end
      end
    ]
  ]
  ```

  > #### Test coverage configuration best practices {: .tip}
  >
  > It is advised to set the test coverage `:output` for all workspace projects
  > pointing to the same directory with the application name set as prefix. This
  > way you can easily cache it in CI pipelines.
  >
  > A custom check can be used to ensure it:
  >
  > ```elixir 
  > [
  >   module: Workspace.Checks.ValidateConfig,
  >   description: "all projects must have test_coverage[:output] properly set",
  >   opts: [
  >     validate: fn config ->
  >       coverage_opts = config[:test_coverage] || []
  >       output = coverage_opts[:output]
  >
  >       cond do
  >         is_nil(output) ->
  >           {:error, ":output option not defined under :test_coverage settings"}
  >
  >         not String.ends_with?(output, Atom.to_string(config[:app])) ->
  >           {:error, ":output must point to a folder with the same name as the app name"}
  >
  >         true ->
  >           {:ok, ""}
  >       end
  >     end
  >   ]
  > ]
  > ```
  >
  > And in your projects `mix.exs`:
  >
  > ```elixir
  > test_coverage: [
  >   output: "path/to/common/app_name"
  > ]
  > ```


  In order to run the tests with `--cover` enabled for all workspace projects you
  should run:

      mix workspace.run -t test -- --cover

  ## Coverage thresholds

  The task supports two coverage thresholds, the error threshold and the warning
  threshold.

  The error threshold can be configured by setting the `:threshold` option under
  `:test_coverage` on the project's config. If not set it defaults to `90%`. If
  any project has a coverage below the error threshold then **the command will fail**.

  > #### Allowing project failures {: .tip}
  >
  > When restructuring a large codebase some extracted projects will not have the
  > desired coverage. Instead of setting a very low threshold or adding tests
  > directly, you can explicitely allow these projects to fail. In order to do this
  > you have to set the `:allow_failure` flag of the `:test_coverage` settings. For
  > example:
  >
  > ```elixir
  > test_coverage: [
  >   allow_failure: [:project_a, :project_b]
  >   ...
  > ]
  > ```
  >
  > In this case the error messages will be normally printed, but the exit code of
  > the command will not be affected.
  >
  > Notice that this does not affect the output and exit code `mix test --cover` if
  > executed directly in the project.

  Warning threshold can be configured by setting the `:warning_threshold` option. If
  not set it defaults to `error_threshold + (100 - error_threshold)/2`. All project
  and module coverages that have are below the warning threshold are logged as
  warnings.

  Notice that by default modules that have coverage above the warning threshold are
  not logged. You can force the logging of all modules by setting the `--verbose`
  flag.

  > #### Workspace overall threshold {: .info}
  >
  > Similar to the individual project's coverage the overall test coverage is also
  > calculated on the workspace level.
  >
  > In order to specify error and warning thresholds you need to set the corresponding
  > options under the `:test_coverage` key of the workspace settings, for example:
  >
  > ```elixir
  > test_coverage: [
  >   threhsold: 70,
  >   warning_threshold: 95
  > ]
  > ```
  >
  > Notice that the overall coverage will be reported only for the projects which are
  > enabled on each invocation of the `mix workspace.test.coverage` task

  ## Exporting coverage

  By default the coverage results are not exported but only logged. You can however specify
  one or more exporters in your workspace `:test_coverage` config. Each exporter is
  expected to by a function that accepts as input a workspace and a list of tuples of the form:

  ```elixir
  {module :: module(), path :: binary(), function_data, line_data}
  ```

  It is responsible for processing the coverage data and generating a report in any format.
  Officially we support the following exporters

  ### `lcov` exporter 

  Generates an lcov file with both line and function coverage stats

  > #### Sample config {: .info}
  >  
  > ```elixir
  > test_coverage: [
  >   exporters: [
  >     lcov: fn workspace, coverage_stats -> 
  >       Workspace.Coverage.export_lcov(
  >         workspace,
  >         coverage_stats,
  >         [output_path: "artifacts/coverage"]
  >       )
  >     end
  >   ]
  > ]
  > ```

  ## Command line options

  #{CliOpts.docs(@options_schema)}
  """
  use Mix.Task

  import Workspace.Cli

  @preferred_cli_env :test

  @impl true
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts, args: _args, extra: _extra, invalid: []} = opts

    workspace = Mix.WorkspaceUtils.load_and_filter_workspace(opts)

    paths =
      workspace
      |> Workspace.filter(opts)
      |> Workspace.projects()
      |> Enum.filter(fn project -> !project.skip end)
      |> Enum.map(&cover_compile_paths/1)

    compile_paths = Enum.map(paths, &elem(&1, 2)) |> List.flatten()

    pid = cover_compile(compile_paths)

    # Silence analyse import messages emitted by cover
    {:ok, string_io} = StringIO.open("")
    Process.group_leader(pid, string_io)

    log(highlight("importing cover results", :bright), prefix: :header)

    Enum.each(paths, fn {project, cover_paths, _compile_paths} ->
      import_cover_results(project, cover_paths, workspace.workspace_path)
    end)

    newline()
    log(highlight("analysing coverage data", :bright), prefix: :header)

    coverage_stats =
      workspace
      |> calculate_coverage()
      |> List.flatten()

    project_statuses =
      workspace
      |> Workspace.filter(opts)
      |> Workspace.projects()
      |> Enum.filter(fn project -> !project.skip end)
      |> Enum.reduce([], fn project, acc ->
        {coverage, module_stats} =
          Workspace.Coverage.project_coverage_stats(coverage_stats, project)

        {error_threshold, warning_threshold} =
          project_coverage_thresholds(project.config[:test_coverage])

        status =
          coverage_status(
            project.app,
            coverage,
            error_threshold,
            warning_threshold,
            workspace.config[:test_coverage][:allow_failure] || []
          )

        log_with_title(
          project_name(project),
          [
            "total coverage ",
            highlight(
              [:io_lib.format("~.2f", [coverage]), "%"],
              [:bright, status_color(status)]
            ),
            " [threshold #{error_threshold}%]"
          ],
          prefix: :header
        )

        print_module_coverage_info(module_stats, error_threshold, warning_threshold, opts)

        [status | acc]
      end)

    {overall_coverage, _module_stats} = Workspace.Coverage.summarize_line_coverage(coverage_stats)

    {error_threshold, warning_threshold} =
      project_coverage_thresholds(workspace.config[:test_coverage])

    status = coverage_status(:workspace, overall_coverage, error_threshold, warning_threshold, [])
    failed = Enum.any?([status | project_statuses], fn status -> status == :error end)

    newline()

    log(
      [
        highlight("workspace coverage ", :bright),
        highlight(
          [:io_lib.format("~.2f", [overall_coverage]), "%"],
          [:bright, status_color(status)]
        ),
        " [threshold #{error_threshold}%]"
      ],
      prefix: :header
    )

    export_coverage(workspace, coverage_stats)

    if failed do
      Mix.raise("coverage for one or more projects below the required threshold")
    end
  end

  defp coverage_status(project, coverage, error_thresold, warning_threshold, allow_failure) do
    cond do
      coverage < error_thresold and project in allow_failure ->
        :error_ignore

      coverage < error_thresold ->
        :error

      coverage < warning_threshold ->
        :warn

      true ->
        :ok
    end
  end

  defp export_coverage(workspace, coverage_stats) do
    exporters = Keyword.get(workspace.config[:test_coverage], :exporters, [])

    if exporters != [] do
      newline()
      log([:bright, "exporting coverage data"], prefix: :header)
    end

    Enum.each(exporters, fn {_name, exporter} ->
      exporter.(workspace, coverage_stats)
    end)
  end

  defp print_module_coverage_info(module_stats, error_threshold, warning_threshold, opts) do
    module_stats
    |> Enum.sort_by(fn {_module, _total, _covered, percentage} -> percentage end)
    |> Enum.each(fn {module, total, covered, percentage} ->
      if percentage < warning_threshold or opts[:verbose] do
        formatted_coverage = :io_lib.format("~.2f", [percentage])

        Mix.shell().info([
          "    ",
          coverage_color(percentage, error_threshold, warning_threshold),
          :bright,
          formatted_coverage,
          "%",
          :reset,
          String.duplicate(" ", 8 - Enum.count(formatted_coverage)),
          inspect(module),
          :light_yellow,
          " (#{covered}/#{total} lines)",
          :reset
        ])
      end
    end)
  end

  @default_error_threshold 90

  defp project_coverage_thresholds(coverage_opts) do
    coverage_opts = coverage_opts || []

    error_threshold = Keyword.get(coverage_opts, :threshold, @default_error_threshold)
    default_warning_threshold = error_threshold + (100 - error_threshold) / 2
    warning_threshold = Keyword.get(coverage_opts, :warning_threshold, default_warning_threshold)

    {error_threshold, warning_threshold}
  end

  defp coverage_color(coverage, error_threshold, _warning_threshold)
       when coverage < error_threshold,
       do: status_color(:error)

  defp coverage_color(coverage, _error_threshold, warning_threshold)
       when coverage < warning_threshold,
       do: status_color(:warn)

  defp coverage_color(_coverage, _error_threshold, _warning_threshold), do: status_color(:ok)

  defp cover_compile_paths(project) do
    test_coverage = project.config[:test_coverage] || []
    output = Keyword.get(test_coverage, :output, "cover")

    compile_path =
      Mix.Project.in_project(
        project.app,
        project.path,
        fn _mixfile ->
          Mix.env(:test)
          Mix.Project.compile_path()
        end
      )

    cover_path = Path.join(project.path, output) |> Path.expand()
    {project, [cover_path], [compile_path]}
  end

  defp cover_compile(compile_paths) do
    # experimental: we want to be able to cover test the test coverage
    # since :cover is a singleton the previous implementation
    #
    # :cover.stop()
    # :cover.start()
    #
    # would cause problems to the cover process started by mix test.
    #
    # this seems to work without issues for now
    pid =
      case :cover.start() do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    for compile_path <- compile_paths do
      case :cover.compile_beam(beams(compile_path)) do
        results when is_list(results) ->
          :ok

        {:error, reason} ->
          Mix.raise(
            "Failed to cover compile directory #{inspect(Path.relative_to_cwd(compile_path))} " <>
              "with reason: #{inspect(reason)}"
          )
      end
    end

    pid
  end

  # Pick beams from the compile_path but if by any chance it is a protocol,
  # gets its path from the code server (which will most likely point to
  # the consolidation directory as long as it is enabled).
  #
  # This is copied from the default elixir test.coverage implementation
  defp beams(dir) do
    consolidation_dir = Mix.Project.consolidation_path()

    consolidated =
      case File.ls(consolidation_dir) do
        {:ok, files} -> files
        _ -> []
      end

    for file <- File.ls!(dir), Path.extname(file) == ".beam" do
      with true <- file in consolidated,
           [_ | _] = path <- :code.which(file |> Path.rootname() |> String.to_atom()) do
        path
      else
        _ -> String.to_charlist(Path.join(dir, file))
      end
    end
  end

  defp import_cover_results(project, cover_paths, workspace_path) do
    app = project.app

    case Enum.flat_map(cover_paths, &Path.wildcard(Path.join(&1, "#{app}*.coverdata"))) do
      [] ->
        Mix.shell().info(
          "#{inspect(app)} - could not find .coverdata file in any of the paths: " <>
            Enum.join(cover_paths, ", ")
        )

      cover_paths ->
        for cover_path <- cover_paths do
          import_cover_result(workspace_path, cover_path, app)
        end
    end
  end

  defp import_cover_result(workspace_path, cover_path, app) do
    path = Workspace.Utils.Path.relative_to(cover_path, workspace_path)

    Mix.shell().info([
      "==> ",
      highlight(inspect(app), :cyan),
      " - importing cover results from ",
      highlight(path, [:light_yellow])
    ])

    :ok = :cover.import(String.to_charlist(cover_path))
  end

  defp calculate_coverage(workspace) do
    :cover.modules()
    |> Enum.sort()
    |> Enum.map(&calculate_module_coverage(&1, workspace))
    |> Enum.filter(fn data -> data != nil end)
  end

  defp calculate_module_coverage(module, workspace) do
    module_path = module.module_info(:compile)[:source]

    path =
      module_path
      |> to_string()
      |> Path.relative_to(workspace.workspace_path)

    # Ignore compiled modules with path:
    # - not relative to the app (e.g. generated by umbrella dependencies)
    # - ignored by configuration
    case Path.type(path) do
      :relative ->
        project = Workspace.parent_project(workspace, to_string(module_path))

        case project do
          nil ->
            Mix.shell().info([
              "    ",
              :light_yellow,
              inspect(module),
              :reset,
              " could not find associated project, ignoring from coverage report"
            ])

            nil

          _other ->
            {:ok, function_data} = :cover.analyze(module, :calls, :function)
            {:ok, line_data} = :cover.analyze(module, :calls, :line)
            {module, project.app, function_data, line_data}
        end

      # ignore non relative paths to the workspace
      _other ->
        nil
    end
  end
end
