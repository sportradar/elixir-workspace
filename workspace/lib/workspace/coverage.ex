defmodule Workspace.Coverage do
  @moduledoc false

  def project_coverage_stats(coverage, project) do
    # coverage per project's module
    project_modules =
      Enum.filter(coverage, fn {_module, app, _function_data, _line_data} ->
        app == project.app
      end)

    summarize_line_coverage(project_modules)
  end

  def summarize_line_coverage(coverage) do
    line_stats =
      coverage
      |> Enum.map(fn {module, _app, _function_data, line_data} ->
        {total_lines, covered_lines, _line_data} = calculate_line_coverage(module, line_data)

        {module, total_lines, covered_lines, percentage(covered_lines, total_lines)}
      end)

    percentage = coverage_percentage(line_stats)

    {percentage, line_stats}
  end

  def export_lcov(coverage, opts \\ []) do
    lcov =
      coverage
      |> Enum.map(fn {module, _app, function_data, line_data} ->
        path = module.module_info(:compile)[:source]

        {total_functions, covered_functions, function_data} =
          calculate_function_coverage(module, function_data)

        {total_lines, covered_lines, line_data} = calculate_line_coverage(module, line_data)

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

    # TODO: set the file from cli args
    filename = opts[:filename] || "coverage.lcov"
    output_path = opts[:output_path] || "cover"

    output_path = Path.join(output_path, filename) |> Path.expand()

    Mix.shell().info([
      "    ",
      "saving lcov report to ",
      :light_yellow,
      output_path,
      :reset
    ])

    File.mkdir_p!(Path.dirname(output_path))
    File.write!(output_path, lcov, [:write])
  end

  defp coverage_percentage(line_stats) do
    total_lines =
      line_stats
      |> Enum.map(&elem(&1, 1))
      |> Enum.sum()

    covered_lines =
      line_stats
      |> Enum.map(&elem(&1, 2))
      |> Enum.sum()

    percentage(covered_lines, total_lines)
  end

  @doc false
  def calculate_function_coverage(module, results) do
    function_data =
      results
      # TODO: verify that this filtering is correct - check on a big codebase
      # it should always return the same counts
      |> Enum.filter(fn {{mod, _function, _arity}, _count} -> mod == module end)
      |> Enum.map(fn {{_module, function, arity}, count} -> {{function, arity}, count} end)
      |> Enum.filter(fn {{function, _arity}, _count} -> function != :__info__ end)
      |> Enum.map(fn {{function, arity}, count} -> {"#{function}/#{arity}", count} end)
      |> Enum.group_by(fn {function, _count} -> function end, fn {_function, count} -> count end)
      |> Enum.map(fn {function, counts} -> {function, Enum.sum(counts)} end)
      |> Enum.sort_by(fn {function, _counts} -> function end)

    total_functions = length(function_data)
    covered_functions = Enum.count(function_data, fn {_function, count} -> count > 0 end)

    {total_functions, covered_functions, function_data}
  end

  @doc false
  def calculate_line_coverage(module, results) do
    line_data =
      results
      |> Enum.filter(fn {{mod, _line}, _count} -> mod == module end)
      |> Enum.map(fn {{_module, line}, count} -> {line, count} end)
      |> Enum.filter(fn {line, _count} -> line != 0 end)
      |> Enum.group_by(fn {line, _count} -> line end, fn {_line, count} -> count end)
      |> Enum.map(fn {line, counts} -> {line, Enum.sum(counts)} end)
      |> Enum.sort_by(fn {line, _counts} -> line end)

    total_lines = length(line_data)
    uncovered_lines = Enum.count(line_data, fn {_line, count} -> count == 0 end)
    covered_lines = total_lines - uncovered_lines

    {total_lines, covered_lines, line_data}
  end

  defp percentage(0, 0), do: 100.0
  defp percentage(covered, total), do: covered / total * 100

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
