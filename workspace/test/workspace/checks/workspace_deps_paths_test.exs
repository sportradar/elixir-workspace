defmodule Workspace.Checks.WorkspaceDepsPathsTest do
  use Workspace.CheckCase

  alias Workspace.Checks.WorkspaceDepsPaths

  setup do
    {:ok, check} =
      Workspace.Check.validate(module: WorkspaceDepsPaths)

    %{check: check}
  end

  test "error if invalid dependencies relative paths", %{check: check} do
    project1 = project_fixture([app: :foo, deps: []], path: "packages")
    project2 = project_fixture([app: :bar, deps: [{:foo, path: "../foo"}]], path: "tools")
    workspace = workspace_fixture([project1, project2])

    results = WorkspaceDepsPaths.check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_check_status(results, :bar, :error)

    expected = [
      "path mismatches for the following dependencies: ",
      "\n",
      "    → ",
      :yellow,
      ":foo",
      :reset,
      " expected ",
      :light_cyan,
      "\"../../packages/foo\"",
      :reset,
      " got ",
      :light_cyan,
      "\"../foo\"",
      :reset
    ]

    assert_formatted_result(results, :bar, expected)
  end

  test "no error if all relative paths are valid", %{check: check} do
    project1 = project_fixture(app: :foo, deps: [])
    project2 = project_fixture(app: :bar, deps: [{:foo, path: "../foo"}])
    workspace = workspace_fixture([project1, project2])

    results = WorkspaceDepsPaths.check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_check_status(results, :bar, :ok)

    expected = ["all workspace dependencies have a valid path"]

    assert_formatted_result(results, :foo, expected)
  end
end
