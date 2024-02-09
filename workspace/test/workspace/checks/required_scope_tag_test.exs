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

    expected = [
      "missing tag with scope: ",
      :light_red,
      ":type",
      :reset
    ]

    assert_formatted_result(results, :test, expected)
  end

  test "error if required scope tags are defined multiple times and multiple is false", %{
    check: check
  } do
    project = project_fixture(app: :test, workspace: [tags: [{:type, :foo}, {:type, :bar}]])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :error)

    expected = [
      "multiple tags with scope ",
      :light_cyan,
      ":type",
      :reset,
      " defined: ",
      :light_red,
      "[type: :foo, type: :bar]",
      :reset
    ]

    assert_formatted_result(results, :test, expected)
  end

  test "no error if scoped tag is set", %{check: check} do
    project = project_fixture(app: :test, workspace: [tags: [:bar, {:type, :baz}]])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :ok)

    expected = [
      "defined tags with ",
      :light_cyan,
      ":type",
      :reset,
      "scope: ",
      :light_green,
      "[type: :baz]",
      :reset
    ]

    assert_formatted_result(results, :test, expected)
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

    expected = [
      "defined tags with ",
      :light_cyan,
      ":type",
      :reset,
      "scope: ",
      :light_green,
      "[type: :foo, type: :baz]",
      :reset
    ]

    assert_formatted_result(results, :test, expected)
  end
end
