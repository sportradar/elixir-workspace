defmodule Workspace.TopologyTest do
  use ExUnit.Case
  import TestUtils

  setup do
    project_a = project_fixture(app: :foo)
    project_b = project_fixture(app: :bar)

    workspace = workspace_fixture([project_a, project_b])

    %{workspace: workspace}
  end

  describe "parent_project/2" do
    test "returns the valid parent project with a full path", %{workspace: workspace} do
      assert project =
               Workspace.Topology.parent_project(
                 workspace,
                 "/usr/local/workspace/packages/foo/file.ex"
               )

      assert project.app == :foo
    end

    test "returns the valid parent project with a relative path", %{workspace: workspace} do
      assert project = Workspace.Topology.parent_project(workspace, "packages/foo/file.ex")

      assert project.app == :foo
    end

    test "returns nil if invalid path", %{workspace: workspace} do
      assert Workspace.Topology.parent_project(workspace, "invalid/file.ex") == nil
    end
  end
end
