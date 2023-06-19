defmodule Workspace.Checkers.ValidateConfigPath do
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
    config_attribute = Keyword.fetch!(check.opts, :config_attribute)
    expected_path = Keyword.fetch!(check.opts, :expected_path)

    Workspace.Checker.check_projects(workspace, check, fn project ->
      check_config_path(project, config_attribute, expected_path)
    end)
  end

  @impl Workspace.Checker
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta,
        check: check,
        project: project
      }) do
    attribute = check.opts[:config_attribute]

    expected = Workspace.Utils.relative_path_to(meta[:expected], project.path)

    configured =
      case meta[:configured] do
        nil -> "nil"
        configured -> Workspace.Utils.relative_path_to(configured, project.path)
      end

    [
      "expected ",
      :light_yellow,
      ":#{attribute} ",
      :reset,
      "to be ",
      :light_yellow,
      "#{expected}",
      :reset,
      ", got: ",
      :light_red,
      "#{configured}"
    ]
  end

  def format_result(%Workspace.Check.Result{
        check: check,
        meta: meta,
        project: project,
        status: :ok
      }) do
    attribute = check.opts[:config_attribute]
    expected = Workspace.Utils.relative_path_to(meta[:expected], project.path)

    [
      :light_yellow,
      ":#{attribute} ",
      :reset,
      "is set to ",
      :light_yellow,
      "#{expected}"
    ]
  end

  defp check_config_path(project, config_attribute, expected_path) do
    expected_path = make_absolute(project.workspace_path, expected_path)
    configured_path = make_absolute(project.path, project.config[config_attribute])

    if configured_path == expected_path do
      {:ok, check_metadata(expected_path, configured_path)}
    else
      {:error, check_metadata(expected_path, configured_path)}
    end
  end

  defp make_absolute(_base_path, nil), do: nil

  defp make_absolute(base_path, relative) do
    base_path
    |> Path.join(relative)
    |> Path.expand()
  end

  defp check_metadata(expected, configured) do
    [expected: expected, configured: configured]
  end
end
