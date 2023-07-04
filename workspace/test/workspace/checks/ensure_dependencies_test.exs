defmodule Workspace.Checks.EnsureDependenciesTest do
  use CheckTest.Case
  alias Workspace.Checks.EnsureDependencies

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        module: EnsureDependencies,
        opts: [
          deps: [:foo, :bar]
        ]
      )

    %{check: check}
  end

  test "error if dependencies are missing", %{check: check} do
    project = project_fixture(app: :test, deps: [])
    workspace = workspace_fixture([project])

    results = EnsureDependencies.check(workspace, check)

    assert_check_status(results, :test, :error)

    expected = [
      "the following required dependencies are missing: ",
      :light_cyan,
      "[:foo, :bar]",
      :reset
    ]

    assert_formatted_result(results, :test, expected)
  end

  test "no error if all dependencies are present", %{check: check} do
    project = project_fixture(app: :test, deps: [{:foo, "1.0.0"}, {:bar, "2.0.0"}])
    workspace = workspace_fixture([project])

    results = EnsureDependencies.check(workspace, check)

    assert_check_status(results, :test, :ok)

    expected = ["all required dependencies are present"]

    assert_formatted_result(results, :test, expected)
  end
end
