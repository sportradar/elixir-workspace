defmodule Workspace.Checks.ForbiddenDeps do
  @moduledoc """
  Ensures that the given dependencies are not defined.

  This check can be used to ensure that all projects or a subset of your
  mono-repo projects do not have some dependencies defined.

  > #### Common use cases {: .tip}
  >
  > A common use case for this check is when you want to deprecate a
  > specific dependency in favor of another one and want to ensure that
  > it is not introduced again in your workspace.

  ## Configuration

  It expects the following configuration parameters:

  * `:deps` - a list of forbidden dependencies

  > #### Example {: .tip}
  > 
  > The following check ensures that `:foo` and `:bar` are not defined
  > as dependencies across the workspace
  >
  > ```elixir
  > [
  >   module: Workspace.Checks.ForbiddenDeps,
  >   description: ":foo and :bar are forbidden deps",
  >   opts: [
  >     deps: [:foo, :bar]
  >   ]
  > ]
  > ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def check(workspace, check) do
    deps = Keyword.fetch!(check[:opts], :deps)

    Workspace.Check.check_projects(workspace, check, fn project ->
      ensure_forbidden_dependencies(project, deps)
    end)
  end

  defp ensure_forbidden_dependencies(project, deps) do
    configured_deps = Enum.map(project.config[:deps], &elem(&1, 0))

    forbidden_deps = Enum.filter(deps, fn dep -> dep in configured_deps end)

    case forbidden_deps do
      [] -> {:ok, check_metadata(forbidden_deps)}
      forbidden_deps -> {:error, check_metadata(forbidden_deps)}
    end
  end

  defp check_metadata(forbidden_deps) do
    [forbidden_deps: forbidden_deps]
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    [
      "the following forbidden dependencies were detected: ",
      :light_cyan,
      inspect(meta[:forbidden_deps]),
      :reset
    ]
  end

  def format_result(%Workspace.Check.Result{status: :ok}) do
    ["no forbidden dependencies were detected"]
  end
end
