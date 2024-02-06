defmodule Workspace.Checks.ValidateTagsTest do
  use Workspace.CheckCase
  alias Workspace.Checks.ValidateTags

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateTags,
        opts: [
          allowed: [:foo, {:foo, :bar}]
        ]
      )

    %{check: check}
  end

  test "error if invalid tags are defined", %{check: check} do
    project = project_fixture([app: :test], tags: [:bar, {:foo, :baz}])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :error)

    expected = [
      "the following tags are not allowed: ",
      :light_red,
      "[:bar, {:foo, :baz}]",
      :reset
    ]

    assert_formatted_result(results, :test, expected)
  end

  test "no error if no forbidden tags are set", %{check: check} do
    project = project_fixture([app: :test], tags: [:foo, {:foo, :bar}])
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :ok)

    expected = ["all tags are valid"]

    assert_formatted_result(results, :test, expected)
  end

  test "no error if no tags are set", %{check: check} do
    project = project_fixture(app: :test)
    workspace = workspace_fixture([project])

    results = check[:module].check(workspace, check)

    assert_check_status(results, :test, :ok)

    expected = ["all tags are valid"]

    assert_formatted_result(results, :test, expected)
  end
end
