defmodule Workspace.Checks.ForbiddenDepsTest do
  use Workspace.CheckCase
  alias Workspace.Checks.ForbiddenDeps

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: ForbiddenDeps,
        opts: [
          deps: [:foo, :bar]
        ]
      )

    %{check: check}
  end

  test "error if dependencies are defined", %{check: check} do
    project = Workspace.Test.project_fixture(:test, "test", deps: [{:foo}])
    workspace = Workspace.Test.workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :error)

    assert_plain_result(
      results,
      :test,
      "the following forbidden dependencies were detected: [:foo]"
    )
  end

  test "no error if no forbidden deps are set", %{check: check} do
    project = Workspace.Test.project_fixture(:test, "test", deps: [])
    workspace = Workspace.Test.workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :ok)
    assert_plain_result(results, :test, "no forbidden dependencies were detected")
  end
end
