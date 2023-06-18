defmodule Workspace.Check.ResultTest do
  use ExUnit.Case

  alias Workspace.Check.Result

  @sample_workspace_path "test/fixtures/sample_workspace"

  setup do
    project_path = Path.join(@sample_workspace_path, "project_a")
    project = Workspace.Project.new(project_path, @sample_workspace_path)

    %{
      check: [check: CheckModule],
      project: project
    }
  end

  test "new/2", %{check: check, project: project} do
    result = Result.new(check, project)

    assert result.checker == CheckModule
    assert result.check == check
    assert result.project == project
    assert result.status == nil
  end

  test "set_status/2", %{check: check, project: project} do
    result =
      Result.new(check, project)
      |> Result.set_status(:ok)

    assert result.status == :ok
  end

  test "set_metadata/2", %{check: check, project: project} do
    result =
      Result.new(check, project)
      |> Result.set_metadata(error: "an error")

    assert result.meta == [error: "an error"]
  end
end
