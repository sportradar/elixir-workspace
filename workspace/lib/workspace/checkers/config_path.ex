defmodule Workspace.Checkers.ValidatePath do
  @moduledoc """
  Checks that the given path is properly configured

  This is useful in cases you want to specify a common path for some of
  your project's artifacts, e.g. `deps_path` or `build_path`. This will
  check that the configuration option of the given project matches the
  expected path. Notice that the expected path is always considered to
  be relative to the project's workspace path.

  ## Configuration

  It expects the following configuration parameters:

  * `:config_attribute` - the configuration attribute to check
  * `:expected_path` - relative path with respect to the workspace root

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
  def check(workspace, check) do
    config_attribute = Keyword.fetch!(check[:opts], :config_attribute)
    expected_path = Keyword.fetch!(check[:opts], :expected_path)

    Workspace.Checker.check_projects(workspace, check, fn project ->
      check_config_path(project, config_attribute, expected_path)
    end)
  end

  defp check_config_path(project, config_attribute, expected_path) do
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
      {:error, [expected: expected_path, configured_path: configured_path]}
    end
  end
end
