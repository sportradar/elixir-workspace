defmodule Workspace.Checks.ValidateConfigPathTest do
  use Workspace.CheckCase
  alias Workspace.Checks.ValidateConfigPath

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: ValidateConfigPath,
        opts: [
          config_attribute: :a_path,
          expected_path: "artifacts/test"
        ]
      )

    %{check: check}
  end

  test "error if config variable is not set", %{check: check} do
    project = Workspace.Test.project_fixture(:foo, "packages/foo", [])
    workspace = Workspace.Test.workspace_fixture([project])
    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)
    assert_plain_result(results, :foo, "expected :a_path to be ../../artifacts/test, got: nil")
  end

  test "error if config variable is not correctly configured", %{check: check} do
    project = Workspace.Test.project_fixture(:foo, "packages/foo", a_path: "foo/bar")
    workspace = Workspace.Test.workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    assert_plain_result(
      results,
      :foo,
      "expected :a_path to be ../../artifacts/test, got: foo/bar"
    )
  end

  test "error if config variable is not a proper path", %{check: check} do
    project = Workspace.Test.project_fixture(:foo, "packages/foo", a_path: [1, 2, 3])
    workspace = Workspace.Test.workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    assert_plain_result(
      results,
      :foo,
      "expected :a_path to be ../../artifacts/test, got: [1, 2, 3]"
    )
  end

  test "ok if variable is properly configured", %{check: check} do
    project = Workspace.Test.project_fixture(:foo, "packages/foo", a_path: "../../artifacts/test")
    workspace = Workspace.Test.workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_plain_result(results, :foo, ":a_path is set to ../../artifacts/test")
  end

  test "works with nested keys" do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: ValidateConfigPath,
        opts: [
          config_attribute: [:deep, :config, :path],
          expected_path: "artifacts/test"
        ]
      )

    project =
      Workspace.Test.project_fixture(:foo, "packages/foo",
        deep: [config: [path: "../../artifacts/test"]]
      )

    workspace = Workspace.Test.workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :ok)
    assert_plain_result(results, :foo, "[:deep, :config, :path] is set to ../../artifacts/test")
  end

  test "error if not proper nested config" do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: ValidateConfigPath,
        opts: [
          config_attribute: [:deep, :config, :path],
          expected_path: "artifacts/test"
        ]
      )

    project = Workspace.Test.project_fixture(:foo, "packages/foo", deep: 12)
    workspace = Workspace.Test.workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    assert_plain_result(
      results,
      :foo,
      "expected [:deep, :config, :path] to be ../../artifacts/test, got: nil"
    )
  end

  test "works with dynamic expected paths" do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: ValidateConfigPath,
        opts: [
          config_attribute: [:a_path],
          expected_path: fn project -> "artifacts/test/#{project.app}" end
        ]
      )

    project = Workspace.Test.project_fixture(:foo, "packages/foo", a_path: "../../artifacts/test")
    workspace = Workspace.Test.workspace_fixture([project])

    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    assert_plain_result(
      results,
      :foo,
      "expected [:a_path] to be ../../artifacts/test/foo, got: ../../artifacts/test"
    )
  end
end
