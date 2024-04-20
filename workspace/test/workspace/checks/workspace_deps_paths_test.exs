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
      "path mismatches for the following dependencies:",
      "→ :foo expected \"../../packages/foo\" got \"../foo\""
    ]

    assert_plain_result(results, :bar, expected)
  end

  test "no error if all relative paths are valid", %{check: check} do
    project1 = project_fixture(app: :foo, deps: [])
    project2 = project_fixture(app: :bar, deps: [{:foo, path: "../foo"}])
    workspace = workspace_fixture([project1, project2])

    results = WorkspaceDepsPaths.check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_check_status(results, :bar, :ok)
    assert_plain_result(results, :foo, "all workspace dependencies have a valid path")
  end
end
