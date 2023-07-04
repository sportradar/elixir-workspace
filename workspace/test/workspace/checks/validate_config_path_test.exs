defmodule Workspace.Checks.ValidateConfigPathTest do
  use CheckTest.Case
  alias Workspace.Checks.ValidateConfigPath

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfigPath,
        opts: [
          config_attribute: :a_path,
          expected_path: "artifacts/test"
        ]
      )

    %{check: check}
  end

  test "error if config variable is not set", %{check: check} do
    project = project_fixture(app: :foo)
    workspace = workspace_fixture([project])
    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    expected = [
      "expected ",
      :light_cyan,
      ":a_path ",
      :reset,
      "to be ",
      :light_cyan,
      "../../artifacts/test",
      :reset,
      ", got: ",
      :light_cyan,
      "nil"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "error if config variable is not correctly configured", %{check: check} do
    project = project_fixture(app: :foo, a_path: "foo/bar")
    workspace = workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    expected = [
      "expected ",
      :light_cyan,
      ":a_path ",
      :reset,
      "to be ",
      :light_cyan,
      "../../artifacts/test",
      :reset,
      ", got: ",
      :light_cyan,
      "foo/bar"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "ok if variable is properly configured", %{check: check} do
    project = project_fixture(app: :foo, a_path: "../../artifacts/test")
    workspace = workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :ok)

    expected = [
      :light_cyan,
      ":a_path ",
      :reset,
      "is set to ",
      :light_cyan,
      "../../artifacts/test"
    ]

    assert_formatted_result(results, :foo, expected)
  end
end
