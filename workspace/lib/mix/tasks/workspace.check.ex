defmodule Mix.Tasks.Workspace.Check do
  @options_schema Workspace.Cli.global_opts() |> Keyword.take([:workspace_path, :config_path])

  @shortdoc "Runs configured checkers on the current workspace"

  @moduledoc """

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """

  use Mix.Task

  def run(argv) do
    %{parsed: opts, args: _args, extra: _extra} = CliOpts.parse!(argv, @options_schema)
    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    config_path = Keyword.fetch!(opts, :config_path)

    # TODO: fix paths, it should handle relative paths wrt cwd
    config = Workspace.config(Path.join(workspace_path, config_path))

    ensure_checks(config.checks)

    workspace = Workspace.new(workspace_path, config)

    Mix.shell().info([
      :green,
      "==> ",
      :reset,
      "running #{length(config.checks)} workspace checks on the workspace"
    ])

    Mix.shell().info("")

    config.checks
    |> Enum.with_index(fn check, index -> Keyword.put(check, :index, index) end)
    |> Enum.map(fn check -> check[:check].check(workspace, check) end)
    |> List.flatten()
    |> Enum.group_by(fn result -> result.index end)
    |> Enum.each(fn {check_index, results} ->
      print_check_status(check_index, results, config.checks)
    end)
  end

  # TODO: validate checks are properly defined modules are valid
  # TODO: make checks a struct
  defp ensure_checks(checks) do
    if checks == [] do
      # TODO: improve the error message, add an example
      Mix.raise("No checkers config found in workspace config")
    end
  end

  defp print_check_status(index, results, checks) do
    check = Enum.at(checks, index)
    status = check_status(results)

    Mix.shell().info([
      "==> ",
      :bright,
      Keyword.fetch!(check, :description),
      :reset,
      " - ",
      :cyan,
      status_color(status),
      status_text(status),
      :reset
    ])

    for result <- results do
      Mix.shell().info([
        "    ",
        status_color(result.status),
        status_text(result.status),
        :reset,
        :cyan,
        " #{result.project.app}",
        :reset,
        " - ",
        check_message(result)
      ])
    end
  end

  defp check_status([]), do: :ok
  defp check_status([%Workspace.CheckResult{status: :error} | _rest]), do: :error
  defp check_status([_result | rest]), do: check_status(rest)

  defp status_color(:error), do: :red
  defp status_color(:ok), do: :green

  defp status_text(:error), do: "ERROR"
  defp status_text(:ok), do: "OK"

  defp strip_elixir_prefix(module) when is_atom(module),
    do: strip_elixir_prefix(Atom.to_string(module))

  defp strip_elixir_prefix("Elixir." <> module), do: module
  defp strip_elixir_prefix(module), do: module

  # TODO: color code support for check messages
  defp check_message(result) do
    result.checker.format_result(result)
  end
end
