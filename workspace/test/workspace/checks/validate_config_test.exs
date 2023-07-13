defmodule Workspace.Checks.ValidateConfigTest do
  use CheckTest.Case
  alias Workspace.Checks.ValidateConfig

  setup do
    %{workspace: Workspace.new("test/fixtures/sample_workspace")}
  end

  test "raises if no validate function is set", %{workspace: workspace} do
    check = [
      module: ValidateConfig,
      opts: [],
      only: [:project_a]
    ]

    assert_raise KeyError, fn -> ValidateConfig.check(workspace, check) end
  end

  test "runs the given validation function", %{workspace: workspace} do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfig,
        opts: [
          validate: fn config -> {:error, "an error detected for #{config[:app]}"} end
        ],
        only: [:project_a]
      )

    results = ValidateConfig.check(workspace, check)
    assert_check_status(results, :project_a, :error)
    assert_check_meta(results, :project_a, message: "an error detected for project_a")
    assert_formatted_result(results, :project_a, "an error detected for project_a")

    for {app, project} <- workspace.projects, app != :project_a do
      assert_check_status(results, project.app, :skip)
      assert_formatted_result(results, project.app, nil)
    end
  end

  test "raises if the validation function does not return a supported status", %{
    workspace: workspace
  } do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfig,
        opts: [
          validate: fn _config -> {:invalid, "invalid"} end
        ],
        only: [:project_a]
      )

    message = """
    validate function must return a {status, message} tuple where status \
    one of [:ok, :error, :skip], got: invalid\
    """

    assert_raise ArgumentError, message, fn -> ValidateConfig.check(workspace, check) end
  end

  test "raises if the validation function does not return a binary message", %{
    workspace: workspace
  } do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfig,
        opts: [
          validate: fn _config -> {:error, :error} end
        ],
        only: [:project_a]
      )

    message = """
    validate function must return a {status, message} tuple where \
    message must be a string, got: :error\
    """

    assert_raise ArgumentError, message, fn -> ValidateConfig.check(workspace, check) end
  end

  test "raises if the validation function does not return a proper tuple", %{
    workspace: workspace
  } do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfig,
        opts: [
          validate: fn _config -> {:error, :error, :error} end
        ],
        only: [:project_a]
      )

    message =
      "validate function must return a {status, message} tuple, got {:error, :error, :error}"

    assert_raise ArgumentError, message, fn -> ValidateConfig.check(workspace, check) end
  end
end
