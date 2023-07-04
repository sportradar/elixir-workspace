defmodule Mix.Tasks.Workspace.Test.Coverage do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path,
                    :project,
                    :affected,
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

  ## Exporting coverage

  This task assumes that `mix test` has been executed with `--cover` and the
  `:export` option under `:test_coverage` set. 

  ## Command line options

  #{CliOpts.docs(@options_schema)}
  """
  use Mix.Task

  alias Workspace.Cli

  @impl true
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts, args: _args, extra: _extra, invalid: []} = opts

    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    config = Workspace.config(Path.join(workspace_path, config_path))
    workspace = Workspace.new(workspace_path, config)

    paths =
      workspace.projects
      |> Workspace.Cli.filter_projects(opts)
      |> Enum.filter(fn project -> !project.skip end)
      |> Enum.map(&cover_compile_paths/1)

    compile_paths = Enum.map(paths, &elem(&1, 2)) |> List.flatten()

    pid = cover_compile(compile_paths)

    # Silence analyse import messages emitted by cover
    {:ok, string_io} = StringIO.open("")
    Process.group_leader(pid, string_io)

    Cli.log("importing cover results")

    Enum.each(paths, fn {app, cover_paths, _compile_paths} ->
      import_cover_results(app, cover_paths, workspace_path)
    end)

    Cli.newline()
    Cli.log("generating coverage report")

    coverage_stats =
      workspace
      |> calculate_coverage()
      |> List.flatten()

    workspace.projects
    |> Workspace.Cli.filter_projects(opts)
    |> Enum.filter(fn project -> !project.skip end)
    |> Enum.each(fn project ->
      {coverage, module_stats} =
        Workspace.Coverage.project_coverage_stats(coverage_stats, project)

      Cli.log(
        inspect(project.app),
        [
          "total coverage ",
          Cli.highlight(
            [:io_lib.format("~.2f", [coverage]), "%"],
            [:bright, coverage_color(coverage)]
          )
        ],
        section_style: :cyan
      )

      print_module_coverage_info(module_stats)
    end)

    Workspace.Coverage.report(coverage_stats, :summary)
  end

  defp print_module_coverage_info(module_stats) do
    module_stats
    |> Enum.sort_by(fn {_module, _total, _covered, percentage} -> percentage end)
    |> Enum.each(fn {module, total, covered, percentage} ->
      formatted_coverage = :io_lib.format("~.2f", [percentage])

      Mix.shell().info([
        "    ",
        coverage_color(percentage),
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
    end)
  end

  defp coverage_color(coverage) when coverage < 50, do: :red
  defp coverage_color(coverage) when coverage < 75, do: :yellow
  defp coverage_color(_coverage), do: :green

  defp cover_compile_paths(project) do
    test_coverage = project.config[:test_coverage] || []
    output = Keyword.get(test_coverage, :output, "cover")

    compile_path =
      Mix.Project.in_project(
        project.app,
        project.path,
        fn _mixfile ->
          Mix.Project.compile_path()
        end
      )

    cover_path = Path.join(project.path, output) |> Path.expand()
    {project.app, [cover_path], [compile_path]}
  end

  defp cover_compile(compile_paths) do
    _ = :cover.stop()
    {:ok, pid} = :cover.start()

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

  defp import_cover_results(app, cover_paths, workspace_path) do
    case Enum.flat_map(cover_paths, &Path.wildcard(Path.join(&1, "#{app}*.coverdata"))) do
      [] ->
        Mix.shell().error(
          "#{app} - could not find .coverdata file in any of the paths: " <>
            Enum.join(cover_paths, ", ")
        )

      entries ->
        for entry <- entries, path = Workspace.Utils.relative_path_to(entry, workspace_path) do
          Cli.log(
            inspect(app),
            [
              "importing cover results from ",
              Cli.highlight(path, [:light_yellow])
            ],
            section_style: :cyan
          )

          :ok = :cover.import(String.to_charlist(entry))
        end
    end
  end

  defp calculate_coverage(workspace) do
    :cover.modules()
    |> Enum.sort()
    |> Enum.map(&calculate_module_coverage(&1, workspace))
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
        project = Workspace.file_project(workspace, to_string(module_path))
        {:ok, function_data} = :cover.analyze(module, :calls, :function)
        {:ok, line_data} = :cover.analyze(module, :calls, :line)
        {module, project.app, function_data, line_data}

      # ignore non relative paths to the workspace
      _other ->
        nil
    end
  end
end
