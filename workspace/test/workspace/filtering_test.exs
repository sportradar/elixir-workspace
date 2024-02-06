defmodule Workspace.FilteringTest do
  use ExUnit.Case
  import TestUtils

  setup do
    project_a = project_fixture(app: :foo)
    project_b = project_fixture(app: :bar)

    workspace = workspace_fixture([project_a, project_b])

    %{workspace: workspace}
  end

  describe "run/2" do
    test "filters and updates the given workspace", %{workspace: workspace} do
      workspace = Workspace.Filtering.run(workspace, exclude: [:bar])

      assert workspace.projects[:bar].skip
      refute workspace.projects[:foo].skip
    end

    test "if app in ignore skips the project", %{workspace: workspace} do
      workspace = Workspace.Filtering.run(workspace, exclude: ["bar"])

      assert Workspace.project!(workspace, :bar).skip
      refute Workspace.project!(workspace, :foo).skip
    end

    test "if app in selected it is not skipped - everything else is skipped", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, project: ["bar"])

      refute Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :foo).skip
    end

    test "ignore has priority over project", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, exclude: [:bar], project: [:bar])

      assert Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :foo).skip
    end
  end
end
