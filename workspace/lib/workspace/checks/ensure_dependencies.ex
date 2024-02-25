defmodule Workspace.Checks.EnsureDependencies do
  @schema NimbleOptions.new!(
            deps: [
              type: {:list, :atom},
              required: true,
              doc: """
              The list of required dependencies. An error will be raised if
              any of these packages is **not** used as a dependency in any
              workspace project.
              """
            ]
          )
  @moduledoc """
  Checks that the given dependencies are defined.

  This check can be used to ensure that all projects or a subset of your
  mono-repo projects have some required dependencies defined.

  ## Configuration

  #{NimbleOptions.docs(@schema)}

  ## Example

  In order to ensure that all workspace projects use `:ex_doc` and `:credo`
  add the following rule in your `workspace.exs`:

  ```elixir
  [
    module: Workspace.Checks.EnsureDependencies,
    opts: [
      deps: [:ex_doc, :credo]
    ]
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @impl Workspace.Check
  def check(workspace, check) do
    deps = Keyword.fetch!(check[:opts], :deps)

    Workspace.Check.check_projects(workspace, check, fn project ->
      ensure_dependencies(project, deps)
    end)
  end

  defp ensure_dependencies(project, deps) do
    configured_deps = Enum.map(project.config[:deps], &elem(&1, 0))

    missing_deps =
      Enum.filter(deps, fn dep -> dep != project.app and dep not in configured_deps end)

    case missing_deps do
      [] -> {:ok, check_metadata(missing_deps)}
      missing_deps -> {:error, check_metadata(missing_deps)}
    end
  end

  defp check_metadata(missing_deps) do
    [missing_deps: missing_deps]
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    [
      "the following required dependencies are missing: ",
      :light_cyan,
      inspect(meta[:missing_deps]),
      :reset
    ]
  end

  def format_result(%Workspace.Check.Result{status: :ok}) do
    ["all required dependencies are present"]
  end
end
