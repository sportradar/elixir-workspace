defmodule Mix.Tasks.Workspace.Check do
  @options_schema Workspace.Cli.options([:workspace_path, :config_path, :verbose])

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
    |> Enum.map(fn check -> check[:module].check(workspace, check) end)
    |> List.flatten()
    |> Enum.group_by(fn result -> result.index end)
    |> Enum.each(fn {check_index, results} ->
      print_check_status(check_index, results, config.checks, opts)
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

  defp print_check_status(index, results, checks, opts) do
    check = Enum.at(checks, index)
    status = check_status(results)
    results = Enum.sort_by(results, & &1.project.app)

    display_index = String.pad_leading("#{index}", 3, "0")

    Mix.shell().info([
      "==> ",
      :bright,
      status_color(status),
      "C#{display_index} ",
      :reset,
      :bright,
      check[:description],
      :reset
    ])

    for result <- results do
      maybe_print_result(result, opts[:verbose])
    end
  end

  defp maybe_print_result(result, verbose) do
    cond do
      verbose ->
        print_result(result)

      result.status != :ok ->
        print_result(result)

      true ->
        :ok
    end
  end

  defp print_result(result) do
    path = Workspace.Utils.relative_path_to(result.project.path, File.cwd!())

    Mix.shell().info(
      [
        "    ",
        status_color(result.status),
        ":#{result.project.app}",
        :reset,
        " - "
      ] ++ check_message(result) ++ maybe_mix_project(result.status, path)
    )
  end

  defp check_status([]), do: :ok
  defp check_status([%Workspace.Check.Result{status: :error} | _rest]), do: :error
  defp check_status([_result | rest]), do: check_status(rest)

  defp status_color(:error), do: :red
  defp status_color(:ok), do: :green

  defp status_text(:error), do: "ERROR"
  defp status_text(:ok), do: "OK"

  defp strip_elixir_prefix(module) when is_atom(module),
    do: strip_elixir_prefix(Atom.to_string(module))

  defp strip_elixir_prefix("Elixir." <> module), do: module
  defp strip_elixir_prefix(module), do: module

  defp check_message(result) do
    result.module.format_result(result)
    |> maybe_enlist()
  end

  defp maybe_enlist(message) when is_list(message), do: message
  defp maybe_enlist(message), do: [message]

  defp maybe_mix_project(:ok, _path), do: []
  defp maybe_mix_project(:error, path), do: [:reset, :faint, " ", path, :reset]
end
