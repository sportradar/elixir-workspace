defmodule Workspace.Checks.EnforceBoundariesTest do
  use Workspace.CheckCase
  alias Workspace.Checks.EnforceBoundaries

  setup do
    project_a =
      project_fixture(app: :foo, deps: [{:bar, path: "../bar"}], workspace: [tags: [:foo]])

    project_b =
      project_fixture(app: :bar, deps: [{:baz, path: "../baz"}], workspace: [tags: [:bar]])

    project_c = project_fixture(app: :baz, workspace: [tags: [:foo, :bar]])

    workspace = workspace_fixture([project_a, project_b, project_c])

    %{workspace: workspace}
  end

  test "no error with default values", %{workspace: workspace} do
    {:ok, check} =
      Workspace.Check.validate(
        module: EnforceBoundaries,
        opts: [
          tag: :foo
        ]
      )

    results = check[:module].check(workspace, check)
    expected = ["no boundaries crossed"]

    assert_check_status(results, :foo, :ok)
    assert_check_status(results, :bar, :ok)
    assert_check_status(results, :baz, :ok)
    assert_formatted_result(results, :foo, expected)
  end

  test "with allowed tags rule", %{workspace: workspace} do
    {:ok, check} =
      Workspace.Check.validate(
        module: EnforceBoundaries,
        opts: [
          tag: :foo,
          allowed_tags: [{:scope, :shared}]
        ]
      )

    results = check[:module].check(workspace, check)

    assert_check_status(results, :foo, :error)
    assert_check_status(results, :bar, :ok)
    assert_check_status(results, :baz, :ok)

    expected = [
      "a project tagged with ",
      :tag,
      ":foo",
      :reset,
      " can only depend on projects tagged with ",
      :tag,
      "scope:shared",
      :reset,
      " - invalid dependencies: ",
      :project,
      ":bar",
      :reset
    ]

    assert_formatted_result(results, :foo, expected)

    # no error if at least one tag is allowed
    {:ok, check} =
      Workspace.Check.validate(
        module: EnforceBoundaries,
        opts: [
          tag: :foo,
          allowed_tags: [{:scope, :shared}, :bar]
        ]
      )

    results = check[:module].check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_check_status(results, :bar, :ok)
    assert_check_status(results, :baz, :ok)
  end

  test "with forbidden tags rule", %{workspace: workspace} do
    {:ok, check} =
      Workspace.Check.validate(
        module: EnforceBoundaries,
        opts: [
          tag: :foo,
          forbidden_tags: [:bar]
        ]
      )

    results = check[:module].check(workspace, check)

    assert_check_status(results, :foo, :error)
    assert_check_status(results, :bar, :ok)
    assert_check_status(results, :baz, :ok)

    expected = [
      "a project tagged with ",
      :tag,
      ":foo",
      :reset,
      " cannot depend on projects tagged with ",
      :tag,
      ":bar",
      :reset,
      " - invalid dependencies: ",
      :project,
      ":bar",
      :reset
    ]

    assert_formatted_result(results, :foo, expected)

    # no error if at least one tag is allowed
    {:ok, check} =
      Workspace.Check.validate(
        module: EnforceBoundaries,
        opts: [
          tag: :foo,
          allowed_tags: [{:scope, :shared}, :bar]
        ]
      )

    results = check[:module].check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_check_status(results, :bar, :ok)
    assert_check_status(results, :baz, :ok)
  end

  test "with all tags selected", %{workspace: workspace} do
    {:ok, check} =
      Workspace.Check.validate(
        module: EnforceBoundaries,
        opts: [
          tag: :*,
          forbidden_tags: [:bar]
        ]
      )

    results = check[:module].check(workspace, check)

    assert_check_status(results, :foo, :error)
    assert_check_status(results, :bar, :error)
    assert_check_status(results, :baz, :ok)
  end
end
