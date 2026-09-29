defmodule Workspace.Coverage do
  @moduledoc false

  @doc false
  def project_coverage_stats(coverage, project) do
    # coverage per project's module
    project_modules =
      coverage
      |> Enum.filter(fn {_module, app, _function_data, _line_data} ->
        app == project.app
      end)
      |> Enum.reject(fn {module, _app, _function_data, _line_data} ->
        ignored_modules = get_in(project.config, [:test_coverage, :ignore_modules]) || []
        module in ignored_modules
      end)

    summarize_line_coverage(project_modules)
  end

  # TODO: refactor, code repetition with previous function
  @doc false
  def summarize_line_coverage(coverage, workspace) do
    coverage
    |> Enum.reject(fn {module, app, _function_data, _line_data} ->
      project = workspace.projects[app] || []
      ignored_modules = get_in(project.config, [:test_coverage, :ignore_modules]) || []

      module in ignored_modules
    end)
    |> summarize_line_coverage()
  end

  @doc false
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
  # TODO: make them public and document properly since they can be used by exporters.
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

  @doc false
  # Returns the beams of the given compile path. If any of them is a consolidated
  # protocol, its path is taken from the code server, which most likely points to
  # the consolidation directory.
  #
  # This is copied from the default elixir test.coverage implementation
  @spec beams(dir :: Path.t(), consolidation_dir :: Path.t()) :: [charlist()]
  def beams(dir, consolidation_dir) do
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

  @doc false
  @spec ensure_cover_compiled!(result :: list() | {:error, term()}, compile_path :: Path.t()) ::
          :ok
  def ensure_cover_compiled!(results, _compile_path) when is_list(results), do: :ok

  def ensure_cover_compiled!({:error, reason}, compile_path) do
    Mix.raise(
      "Failed to cover compile directory #{inspect(Path.relative_to_cwd(compile_path))} " <>
        "with reason: #{inspect(reason)}"
    )
  end

  defp percentage(0, 0), do: 100.0
  defp percentage(covered, total), do: covered / total * 100
end
