defmodule Workspace.Checks.WorkspaceDepsPathsTest do
  use Workspace.CheckCase

  alias Workspace.Checks.WorkspaceDepsPaths

  setup do
    {:ok, check} =
      Workspace.Check.validate(id: :test_check, module: WorkspaceDepsPaths)

    %{check: check}
  end

  test "error if invalid dependencies relative paths", %{check: check} do
    project1 = Workspace.Test.project_fixture(:foo, "packages/foo", deps: [])
    project2 = Workspace.Test.project_fixture(:bar, "tools/bar", deps: [{:foo, path: "../foo"}])
    workspace = Workspace.Test.workspace_fixture([project1, project2])

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
    project1 = Workspace.Test.project_fixture(:foo, "foo", deps: [])
    project2 = Workspace.Test.project_fixture(:bar, "bar", deps: [{:foo, path: "../foo"}])
    workspace = Workspace.Test.workspace_fixture([project1, project2])

    results = WorkspaceDepsPaths.check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_check_status(results, :bar, :ok)
    assert_plain_result(results, :foo, "all workspace dependencies have a valid path")
  end
end
