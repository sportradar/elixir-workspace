defmodule Workspace.Check.ResultTest do
  use ExUnit.Case

  alias Workspace.Check.Result

  defmodule CheckModule do
    @behaviour Workspace.Check

    @impl true
    def check(_workspace, _check), do: []

    @impl true
    def format_result(_result), do: []
  end

  test "new/2" do
    {:ok, check} = Workspace.Check.validate(id: :test_check, module: CheckModule)
    project = Workspace.Test.project_fixture(:foo, "foo", [])

    result = Result.new(check, project)

    assert result == %Result{module: CheckModule, check: check, project: project}

    assert result.module == CheckModule
    assert result.check == check
    assert result.project == project
    assert result.status == nil
  end

  test "set_status/2" do
    {:ok, check} = Workspace.Check.validate(id: :test_check, module: CheckModule)
    project = Workspace.Test.project_fixture(:foo, "foo", [])

    result =
      Result.new(check, project)
      |> Result.set_status(:ok)

    assert result.status == :ok
  end

  test "set_metadata/2" do
    {:ok, check} = Workspace.Check.validate(id: :test_check, module: CheckModule)
    project = Workspace.Test.project_fixture(:foo, "foo", [])

    result =
      Result.new(check, project)
      |> Result.set_metadata(error: "an error")

    assert result.meta == [error: "an error"]
  end
end
