defmodule Mix.Tasks.Workspace.Graph do
  use Mix.Task

  @shortdoc "Prints the dependency tree"
  @recursive true

  @moduledoc """
  Prints the dependency tree.

      $ mix deps.tree

  If no dependency is given, it uses the tree defined in the `mix.exs` file.

  ## Command line options

    * `--only` - the environment to show dependencies for

    * `--target` - the target to show dependencies for

    * `--exclude` - exclude dependencies which you do not want to see printed.

    * `--format` - Can be set to one of either:

      * `pretty` - uses Unicode code points for formatting the tree.
        This is the default except on Windows.

      * `plain` - does not use Unicode code points for formatting the tree.
        This is the default on Windows.

      * `dot` - produces a DOT graph description of the dependency tree
        in `deps_tree.dot` in the current directory.
        Warning: this will override any previously generated file.

  """
  @switches [
    only: :string,
    target: :string,
    exclude: :keep,
    format: :string,
    workspace_path: :string
  ]

  @project_flags [:workspace_path]

  @impl true
  def run(args) do
    Mix.Project.get!()
    {opts, _args, _} = OptionParser.parse(args, switches: @switches)

    opts
    |> Keyword.take(@project_flags)
    |> Workspace.projects()
    |> Workspace.Graph.print_tree()
  end
end
