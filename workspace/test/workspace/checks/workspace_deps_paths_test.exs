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

  test "supports all dependency formats", %{check: check} do
    deps = [
      {:foo, "~> 0.1", path: "./../foo"},
      {:baz, "~> 0.1"},
      {:qux, git: "https://github.com/x/qux.git"},
      {:quux, "~> 0.1", path: "../wrong"}
    ]

    workspace =
      Workspace.Test.workspace_fixture([
        {:foo, "foo", []},
        {:baz, "baz", []},
        {:qux, "qux", []},
        {:quux, "quux", []},
        {:bar, "bar", [deps: deps]}
      ])

    results = WorkspaceDepsPaths.check(workspace, check)

    # dependencies without a path are not validated
    assert_check_status(results, :bar, :error)

    assert_plain_result(results, :bar, [
      "path mismatches for the following dependencies:",
      "→ :quux expected \"../quux\" got \"../wrong\""
    ])
  end
end
