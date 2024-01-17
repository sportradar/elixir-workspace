defmodule Workspace.Checks.ValidateConfigTest do
  use CheckTest.Case
  alias Workspace.Checks.ValidateConfig

  setup do
    %{workspace: Workspace.new!("test/fixtures/sample_workspace")}
  end

  test "raises if no validate function is set" do
    check = [
      module: ValidateConfig,
      opts: []
    ]

    assert {:error, message} = Workspace.Check.validate(check)

    assert message ==
             "invalid check options: required :validate option not found, received options: []"
  end

  test "with wrong function arity" do
    check = [
      module: ValidateConfig,
      opts: [validate: fn -> :ok end]
    ]

    assert {:error, message} = Workspace.Check.validate(check)

    assert message ==
             "invalid check options: invalid value for :validate option: expected function of arity 1, got: function of arity 0"
  end

  test "runs the given validation function", %{workspace: workspace} do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfig,
        opts: [
          validate: fn config -> {:error, "an error detected for #{config[:app]}"} end
        ],
        only: [:package_a]
      )

    results = ValidateConfig.check(workspace, check)
    assert_check_status(results, :package_a, :error)
    assert_check_meta(results, :package_a, message: "an error detected for package_a")
    assert_formatted_result(results, :package_a, "an error detected for package_a")

    for {app, project} <- workspace.projects, app != :package_a do
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
        only: [:package_a]
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
        only: [:package_a]
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
        only: [:package_a]
      )

    message =
      "validate function must return a {status, message} tuple, got {:error, :error, :error}"

    assert_raise ArgumentError, message, fn -> ValidateConfig.check(workspace, check) end
  end
end
