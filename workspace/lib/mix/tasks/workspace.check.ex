defmodule Mix.Tasks.Workspace.Check do
  @options_schema Workspace.Cli.global_opts()

  @shortdoc "Runs configured checkers on the current workspace"

  @moduledoc """

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """

  use Mix.Task

  alias Workspace.Cli

  def run(_argv) do
    # %{parsed: parsed, args: args, extra: extra} = CliOpts.parse!(argv, @options_schema)

    checks = checks_config()
    workspace = Workspace.new(File.cwd!())

    checks
    |> Enum.map(fn {module, opts} -> module.check(workspace.projects, opts) end)
    |> List.flatten()
    |> Enum.group_by(fn result -> result.project.app end)
    |> Enum.each(fn {app, results} -> print_project_status(app, results) end)
  end

  defp checks_config do
    config =
      Mix.Project.config()
      |> Keyword.get(:workspace, [])
      |> Keyword.get(:checks, [])

    case config do
      [] -> Mix.raise("No checkers config found in mix.exs")
      config -> config
    end
  end

  defp print_project_status(app, results) do
    Cli.info(
      "#{app}",
      "",
      prefix: "==> "
    )

    Enum.each(results, fn result ->
      case result.status do
        :ok ->
          Cli.success("#{result.checker}", "OK", prefix: "\t")

        :error ->
          Cli.error("#{result.checker}", "ERROR", prefix: "\t")
          IO.ANSI.Docs.print(result.error, "text/markdown")
      end
    end)
  end
end
