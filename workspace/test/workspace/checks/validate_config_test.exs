defmodule Workspace.Checks.ValidateConfigTest do
  use ExUnit.Case
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
    assert_project_status(results, :project_a, :error)
    assert_project_meta(results, :project_a, message: "an error detected for project_a")
    assert_formatted_result(results, :project_a, ["an error detected for project_a"])

    for project <- workspace.projects, project.app != :project_a do
      assert_project_status(results, project.app, :skip)
      assert_formatted_result(results, project.app, [])
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

  defp project_result(results, project) do
    Enum.find(results, fn result -> result.project.app == project end)
  end

  defp assert_project_status(results, project, status) do
    result = project_result(results, project)
    assert result.status == status
  end

  defp assert_project_meta(results, project, meta) do
    result = project_result(results, project)
    assert result.meta == meta
  end

  defp assert_formatted_result(results, project, expected) do
    result = project_result(results, project)
    assert ValidateConfig.format_result(result) == expected
  end
end
