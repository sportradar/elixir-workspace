defmodule Workspace.Checks.ValidateConfigPathTest do
  use Workspace.CheckCase
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
      ":a_path",
      :reset,
      " to be ",
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
      ":a_path",
      :reset,
      " to be ",
      :light_cyan,
      "../../artifacts/test",
      :reset,
      ", got: ",
      :light_cyan,
      "foo/bar"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "error if config variable is not a proper path", %{check: check} do
    project = project_fixture(app: :foo, a_path: [1, 2, 3])
    workspace = workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    expected = [
      "expected ",
      :light_cyan,
      ":a_path",
      :reset,
      " to be ",
      :light_cyan,
      "../../artifacts/test",
      :reset,
      ", got: ",
      :light_cyan,
      "[1, 2, 3]"
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
      ":a_path",
      :reset,
      " is set to ",
      :light_cyan,
      "../../artifacts/test"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "works with nested keys" do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfigPath,
        opts: [
          config_attribute: [:deep, :config, :path],
          expected_path: "artifacts/test"
        ]
      )

    project = project_fixture(app: :foo, deep: [config: [path: "../../artifacts/test"]])
    workspace = workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :ok)

    expected = [
      :light_cyan,
      "[:deep, :config, :path]",
      :reset,
      " is set to ",
      :light_cyan,
      "../../artifacts/test"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "error if not proper nested config" do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfigPath,
        opts: [
          config_attribute: [:deep, :config, :path],
          expected_path: "artifacts/test"
        ]
      )

    project = project_fixture(app: :foo, deep: 12)
    workspace = workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    expected = [
      "expected ",
      :light_cyan,
      "[:deep, :config, :path]",
      :reset,
      " to be ",
      :light_cyan,
      "../../artifacts/test",
      :reset,
      ", got: ",
      :light_cyan,
      "nil"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "works with dynamic expected paths" do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfigPath,
        opts: [
          config_attribute: [:a_path],
          expected_path: fn project -> "artifacts/test/#{project.app}" end
        ]
      )

    project = project_fixture(app: :foo, a_path: "../../artifacts/test")
    workspace = workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    expected = [
      "expected ",
      :light_cyan,
      "[:a_path]",
      :reset,
      " to be ",
      :light_cyan,
      "../../artifacts/test/foo",
      :reset,
      ", got: ",
      :light_cyan,
      "../../artifacts/test"
    ]

    assert_formatted_result(results, :foo, expected)
  end
end
