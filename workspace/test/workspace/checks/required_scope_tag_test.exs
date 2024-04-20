defmodule Workspace.Checks.RequiredScopeTagTest do
  use Workspace.CheckCase
  alias Workspace.Checks.RequiredScopeTag

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        module: RequiredScopeTag,
        opts: [
          scope: :type
        ]
      )

    {:ok, check_multiple} =
      Workspace.Check.validate(
        module: RequiredScopeTag,
        opts: [
          scope: :type,
          multiple: true
        ]
      )

    %{check: check, check_multiple: check_multiple}
  end

  test "error if required scope tags are not defined", %{check: check} do
    project = project_fixture(app: :test, workspace: [tags: [:bar, {:foo, :baz}]])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :error)
    assert_plain_result(results, :test, "missing tag with scope: :type")
  end

  test "error if required scope tags are defined multiple times and multiple is false", %{
    check: check
  } do
    project = project_fixture(app: :test, workspace: [tags: [{:type, :foo}, {:type, :bar}]])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :error)

    assert_plain_result(
      results,
      :test,
      "multiple tags with scope :type defined: [type: :foo, type: :bar]"
    )
  end

  test "no error if scoped tag is set", %{check: check} do
    project = project_fixture(app: :test, workspace: [tags: [:bar, {:type, :baz}]])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :ok)
    assert_plain_result(results, :test, "defined tags with :typescope: [type: :baz]")
  end

  test "no error with multiple set to true", %{check: check, check_multiple: check_multiple} do
    project = project_fixture(app: :test, workspace: [tags: [{:type, :foo}, {:type, :baz}]])
    workspace = workspace_fixture([project])

    # with multiple false it emits error
    results = check[:module].check(workspace, check)
    assert_check_status(results, :test, :error)

    # no error with multiple true
    results = check_multiple[:module].check(workspace, check_multiple)
    assert_check_status(results, :test, :ok)
    assert_plain_result(results, :test, "defined tags with :typescope: [type: :foo, type: :baz]")
  end
end
