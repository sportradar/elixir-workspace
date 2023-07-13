defmodule Mix.Tasks.Workspace.Graph do
  @options_schema Workspace.Cli.options([
                    :workspace_path,
                    :config_path
                  ])

  @shortdoc "Prints the dependency tree"

  @moduledoc """
  Prints the dependency tree.

      $ mix deps.tree

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
    workspace = Workspace.new(workspace_path, workspace_config)

    Workspace.Graph.print_tree(workspace)
  end
end
