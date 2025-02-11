defmodule Workspace.Checks.EnsureDependenciesTest do
  use Workspace.CheckCase
  alias Workspace.Checks.EnsureDependencies

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: EnsureDependencies,
        opts: [
          deps: [:foo, :bar]
        ]
      )

    %{check: check}
  end

  test "error if dependencies are missing", %{check: check} do
    workspace = Workspace.Test.workspace_fixture([{:test, "test", deps: []}])

    results = EnsureDependencies.check(workspace, check)

    assert_check_status(results, :test, :error)

    assert_plain_result(
      results,
      :test,
      "the following required dependencies are missing: [:foo, :bar]"
    )
  end

  test "no error if all dependencies are present", %{check: check} do
    project =
      Workspace.Test.project_fixture(:test, "test", deps: [{:foo, "1.0.0"}, {:bar, "2.0.0"}])

    workspace = Workspace.Test.workspace_fixture([project])

    results = EnsureDependencies.check(workspace, check)

    assert_check_status(results, :test, :ok)
    assert_plain_result(results, :test, "all required dependencies are present")
  end
end
