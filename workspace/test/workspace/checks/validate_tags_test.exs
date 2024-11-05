defmodule Workspace.Checks.ValidateTagsTest do
  use Workspace.CheckCase
  alias Workspace.Checks.ValidateTags

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: ValidateTags,
        opts: [
          allowed: [:foo, {:foo, :bar}]
        ]
      )

    %{check: check}
  end

  test "error if invalid tags are defined", %{check: check} do
    project = project_fixture(app: :test, workspace: [tags: [:bar, {:foo, :baz}]])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :error)

    assert_plain_result(
      results,
      :test,
      "the following tags are not allowed: [:bar, {:foo, :baz}]"
    )
  end

  test "no error if no forbidden tags are set", %{check: check} do
    project = project_fixture(app: :test, workspace: [tags: [:foo, {:foo, :bar}]])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :ok)
    assert_plain_result(results, :test, "all tags are valid")
  end

  test "no error if no tags are set", %{check: check} do
    project = project_fixture(app: :test)
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :ok)
    assert_plain_result(results, :test, "all tags are valid")
  end
end
