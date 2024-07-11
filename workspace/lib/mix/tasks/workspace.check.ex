defmodule Mix.Tasks.Workspace.Check do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path,
                    :verbose,
                    :project,
                    :exclude,
                    :tags,
                    :excluded_tags
                  ])

  @shortdoc "Runs configured checkers on the current workspace"

  @moduledoc """
  Check the workspace using the configured checks.

  ## Command Line Options

  #{CliOptions.docs(@options_schema, sort: true, sections: Workspace.CliOptions.doc_sections())}
  """

  use Mix.Task

  import Workspace.Cli

  @impl Mix.Task
  def run(argv) do
    {opts, _args, _extra} = CliOptions.parse!(argv, @options_schema)

    workspace = Mix.WorkspaceUtils.load_and_filter_workspace(opts)

    ensure_checks(workspace.config[:checks])

    log("running #{length(workspace.config[:checks])} workspace checks on the workspace")

    newline()

    workspace.config[:checks]
    |> Enum.with_index(fn check, index -> Keyword.put(check, :index, index) end)
    |> Enum.map(fn check -> run_check(check, workspace, opts) end)
    |> maybe_set_exit_status()
  end

  defp run_check(check, workspace, opts) do
    results = check[:module].check(workspace, check)
    print_check_status(check, results, opts)
    check_status(results)
  end

  defp ensure_checks(checks) do
    if checks == [] do
      Mix.raise("""
      No checks configured in your workspace. In order to add a check add a `checks`
      list in your workspace config and configure the required checks. For example:

          checks: [
            [
              module: Workspace.Checks.ValidateProject,
              description: "all projects must have a description set",
              opts: [
                validate: fn project ->
                  case project.config[:description] do
                    nil -> {:error, "no :description set"}
                    description when is_binary(description) -> {:ok, ""}
                    other -> {:error, "description must be binary}
                  end
                end
              ]
            ]
          }
      """)
    end
  end

  defp print_check_status(check, results, opts) do
    index = check[:index]
    status = check_status(results)
    results = Enum.sort_by(results, & &1.project.app)

    display_index = String.pad_leading("#{index}", 3, "0")

    log_with_title(
      highlight("C#{display_index}", [:bright, status_color(status)]),
      highlight(check[:description], :bright),
      separator: " ",
      prefix: :header
    )

    for result <- results do
      maybe_print_result(result, opts[:verbose])
    end
  end

  defp maybe_print_result(result, verbose) do
    cond do
      verbose ->
        print_result(result)

      result.status in [:error, :warn] ->
        print_result(result)

      true ->
        :ok
    end
  end

  defp print_result(result) do
    path = Workspace.Utils.Path.relative_to(result.project.path, File.cwd!())

    log([
      highlight(status_text(result.status), status_color(result.status)),
      hl(":#{result.project.app}", :code),
      check_message(result),
      maybe_mix_project(result.status, path)
    ])
  end

  defp check_status(results) do
    counts = Enum.group_by(results, fn result -> result.status end)

    cond do
      counts[:error] != nil -> :error
      counts[:warn] != nil -> :warn
      counts[:ok] == nil -> :skip
      true -> :ok
    end
  end

  defp status_text(:error), do: "ERROR "
  defp status_text(:ok), do: "OK    "
  defp status_text(:skip), do: "SKIP  "
  defp status_text(:warn), do: "WARN  "

  defp check_message(%Workspace.Check.Result{status: :skip}), do: " - check skipped"

  # format result handles only success and error, we want the error message for
  # warnings
  defp check_message(%Workspace.Check.Result{status: :warn} = result) do
    Workspace.Check.Result.set_status(result, :error) |> check_message()
  end

  defp check_message(result) do
    case result.module.format_result(result) do
      [] -> []
      "" -> []
      message when is_binary(message) -> [" - ", message]
      message when is_list(message) -> [" - " | message]
    end
  end

  defp maybe_mix_project(:error, path), do: highlight([" ", path], [:reset, :faint])
  defp maybe_mix_project(_other, _path), do: []

  defp maybe_set_exit_status(check_results) do
    failures = Enum.filter(check_results, fn result -> result == :error end)

    if length(failures) > 0 do
      Mix.raise("mix workspace.check failed - errors detected in #{length(failures)} checks")
    end
  end
end
