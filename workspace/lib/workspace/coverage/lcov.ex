defmodule Workspace.Coverage.LCOV do
  @moduledoc """
  [`lcov`](https://github.com/linux-test-project/lcov) coverage exporter.

  > #### Using `lcov` with `genhtml` {: .tip}
  >
  > You can combine the `lcov` exporter, with the `genhtml` command in order
  > to generate an `HTML` coverage report for your complete workspace codebase.
  >
  > From the workspace `Makefile`:
  >
  > ```
  > .PHONY: coverage
  > coverage: ## Generates coverage report
  >   mix workspace.run -t test -- --cover
  >   mix workspace.test.coverage
  >   genhtml artifacts/coverage/lcoverage.lcov -o artifacts/coverage --prefic ${PWD}
  > ```

  ## Options

  The following options are supported:

  * `:filename` - the `.lcov` filename, defaults to `coverage.lcov`
  * `:output_path` - the output path, defaults to `cover` under the current directory

  ## Usage

  In order to enable `LCOV` coverage exporter you can add the following
  to your workspace's `:test_coverage, :exporters` config:

      test_coverage: [
        exporters: [
          lcov: fn workspace, coverage_stats ->
            Workspace.Coverage.LCOV.export(workspace, coverage_stats,
              output_path: "artifacts/coverage"
            )
          end
        ]
      ]
  """

  @behaviour Workspace.Coverage.Exporter

  @impl true
  def export(workspace, coverage, opts \\ []) do
    lcov =
      coverage
      |> Enum.map(fn {module, _app, function_data, line_data} ->
        path = module.module_info(:compile)[:source]

        {total_functions, covered_functions, function_data} =
          Workspace.Coverage.calculate_function_coverage(module, function_data)

        {total_lines, covered_lines, line_data} =
          Workspace.Coverage.calculate_line_coverage(module, line_data)

        format_lcov(
          module,
          path,
          function_data,
          total_functions,
          covered_functions,
          line_data,
          total_lines,
          covered_lines
        )
      end)

    filename = opts[:filename] || "coverage.lcov"
    output_path = opts[:output_path] || "cover"

    output_path =
      case Path.type(output_path) do
        # if it's relative it is considered relative to the workspace root
        :relative ->
          Path.join([workspace.workspace_path, output_path, filename]) |> Path.expand()

        :absolute ->
          Path.join(output_path, filename)
      end

    Workspace.Cli.log([
      "    ",
      "saving lcov report to ",
      :light_yellow,
      output_path,
      :reset
    ])

    File.mkdir_p!(Path.dirname(output_path))
    File.write!(output_path, lcov, [:write])
  end

  @newline "\n"

  defp format_lcov(module, path, functions_coverage, fnf, fnh, lines_coverage, lf, lh) do
    [
      "TN:",
      "#{module}",
      @newline,
      "SF:",
      Path.expand(path),
      @newline,
      function_definitions(functions_coverage),
      instrumented_functions(functions_coverage),
      "FNF:0",
      "#{fnf}",
      @newline,
      "FNH:0",
      "#{fnh}",
      @newline,
      instrumented_lines(lines_coverage),
      "LF:",
      "#{lf}",
      @newline,
      "LH:",
      "#{lh}",
      @newline,
      "end_of_record",
      @newline
    ]
  end

  defp function_definitions(functions_coverage) do
    # TODO: Now we set a dummy function start line, get it from ast
    Enum.map(functions_coverage, fn {function_name, __count} ->
      ["FN:0,", function_name, @newline]
    end)
  end

  # corresponds to the following section of lcov:
  # FNDA:<execution count>,<function name>
  defp instrumented_functions(functions_coverage) do
    Enum.map(functions_coverage, fn {function_name, execution_count} ->
      ["FNDA:", "#{execution_count}", ",", function_name, @newline]
    end)
  end

  # corresponds to the following section of lcov:
  # DA:<line number>,<execution count>[,<checksum>]
  defp instrumented_lines(lines_coverage) do
    Enum.map(lines_coverage, fn {line_number, execution_count} ->
      ["DA:", "#{line_number}", ",", "#{execution_count}", @newline]
    end)
  end
end
