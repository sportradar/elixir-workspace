defmodule Mix.Tasks.Workspace.Graph do
  @custom_options_schema [
    show_status: [
      type: :boolean,
      default: false,
      doc: "If set the status of each project will be included in the output graph"
    ]
  ]
  @options_schema Workspace.Cli.options(
                    [
                      :workspace_path,
                      :config_path
                    ],
                    @custom_options_schema
                  )

  @shortdoc "Prints the dependency tree"

  @moduledoc """
  Prints the workspace graph.

      $ mix workspace.graph

  If no dependency is given, it uses the tree defined in the `mix.exs` file.

  ## Command Line Options

  #{CliOpts.docs(@options_schema)}
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {:ok, opts} = CliOpts.parse(args, @options_schema)
    %{parsed: opts} = opts

    workspace_path = Keyword.get(opts, :workspace_path, File.cwd!())
    workspace_config = Keyword.get(opts, :workspace_config, ".workspace.exs")

    workspace =
      Workspace.new(workspace_path, workspace_config)
      |> maybe_include_status(opts[:show_status])

    Workspace.Graph.print_tree(workspace)
  end

  defp maybe_include_status(workspace, false), do: workspace

  defp maybe_include_status(workspace, true) do
    modified =
      Workspace.modified(workspace)
      |> Enum.map(fn app -> {app, :modified} end)

    affected =
      Workspace.affected(workspace)
      |> Enum.map(fn app -> {app, :affected} end)

    Enum.reduce(modified ++ affected, workspace, fn {app, status}, workspace ->
      Workspace.update_project_status(workspace, app, status)
    end)
  end
end
