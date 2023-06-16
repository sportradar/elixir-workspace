defmodule Workspace.Checkers.ValidatePath do
  @moduledoc """
  Checks that the given path is properly configured

  This is useful in cases you want to specify a common path for some of
  your project's artifacts, e.g. `deps_path` or `build_path`. This will
  check that the configuration option of the given project matches the
  expected path. Notice that the expected path is always considered to
  be relative to the project's workspace path.

  ## Configuration

  In order to configure this checker add the following, under `checkers`,
  in your `workspace.exs`:

  ```elixir
  [
    checker: Workspace.Checkers.ConfigPath,
    config_attribute: :deps_path,
    expected_path: "artifacts/deps"
  ]
  ```
  """
  @behaviour Workspace.Checker

  @impl Workspace.Checker
  def check(workspace, opts) do
    config_attribute = Keyword.fetch!(opts, :config_attribute)
    expected_path = Keyword.fetch!(opts, :expected_path)

    Enum.reduce(workspace.projects, [], fn project, acc ->
      status = check_project(project, config_attribute, expected_path)

      result =
        Workspace.CheckResult.new(__MODULE__, project)
        |> Workspace.CheckResult.set_status(status)

      [result | acc]
    end)
  end

  defp check_project(project, config_attribute, expected_path) do
    expected_path =
      project.workspace_path
      |> Path.join(expected_path)
      |> Path.expand()

    configured_path =
      project.path
      |> Path.join(project.config[config_attribute])
      |> Path.expand()

    if expected_path == configured_path do
      :ok
    else
      {:error,
       """
       Invalid `#{config_attribute}` config attribute. Expected:

       ```
       #{Workspace.Utils.relative_path_to(expected_path, project.path)}
       ```

       Got:

       ```
       #{project.config[config_attribute]}
       ```
       """}
    end
  end
end
