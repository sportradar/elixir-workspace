defmodule Mix.Tasks.Workspace.Deps.Required do
  use Mix.Task

  @shortdoc "Checks that all projects have the given required dependencies"

  @moduledoc """
  """

  @impl true
  def run(_args) do
    Mix.Project.get!()

    case required_deps() do
      [] ->
        """
        No required dependencies are configured in your workspace config. To specify
        required dependencies set the `:required_deps` option under the `workspace` key,
        e.g.:

            workspace: [
              required_deps: [
                [
                  dep: {:ex_doc, "~> 0.28", only: :dev, runtime: false}
                  ignore: [], # specify projects for which this dependency is not required
                  only: []    # this dependency will be checked only for those projects if set
                ]
              ]
            ]

        and run the command again.
        """
        |> String.trim_trailing()
        |> Mix.raise()

      deps ->
        Enum.each(Workspace.projects(), fn project -> check_required_deps(project, deps) end)
    end
  end

  defp required_deps do
    Mix.Project.config()
    |> Keyword.get(:workspace, [])
    |> Keyword.get(:required_deps, [])
  end

  defp check_required_deps({name, path, config}, deps) do
    project_path =
      path
      |> Path.relative_to_cwd()
      |> Path.dirname()

    WorkspaceColors.log(:blue, "checking", [:reset, "#{name}", :green, " #{project_path}"], [])

    missing_deps =
      deps
      |> Enum.filter(fn dep -> missing_dep?(dep, name, config[:deps]) end)
      |> Enum.map(fn dep -> dep[:dep] end)

    if missing_deps != [] do
      """
        The following required deps are not included in the dependencies of `#{name}`:

            #{inspect(missing_deps)}
      """
      |> String.trim_trailing()
      |> Mix.shell().info()
    end
  end

  defp missing_dep?(dep, name, project_deps) do
    cond do
      name in Keyword.get(dep, :ignore, []) ->
        false

      Keyword.get(dep, :only, []) != [] and name not in dep[:only] ->
        false

      true ->
        dep[:dep] not in project_deps
    end
  end
end
