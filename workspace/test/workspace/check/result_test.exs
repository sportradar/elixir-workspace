defmodule Workspace.Check.ResultTest do
  use ExUnit.Case

  alias Workspace.Check.Result

  @sample_workspace_path "test/fixtures/sample_workspace"

  defmodule CheckModule do
    @behaviour Workspace.Check

    @impl true
    def check(_workspace, _check), do: []

    @impl true
    def format_result(_result), do: []
  end

  setup do
    package_path = Path.join(@sample_workspace_path, "package_a")
    project = Workspace.Project.new(package_path, @sample_workspace_path)

    {:ok, check} = Workspace.Check.validate(module: CheckModule)

    %{
      check: check,
      project: project
    }
  end

  test "new/2", %{check: check, project: project} do
    result = Result.new(check, project)

    assert result == %Result{module: CheckModule, check: check, project: project}

    assert result.module == CheckModule
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
