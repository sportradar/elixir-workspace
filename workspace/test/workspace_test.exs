defmodule WorkspaceTest do
  use ExUnit.Case
  import Workspace.TestUtils
  doctest Workspace

  @sample_workspace_path "test/fixtures/sample_workspace"

  setup do
    project_a = project_fixture(app: :foo)
    project_b = project_fixture(app: :bar)

    workspace = workspace_fixture([project_a, project_b])

    %{workspace: workspace}
  end

  describe "new/2" do
    test "creates a workspace struct" do
      {:ok, workspace} = Workspace.new(@sample_workspace_path)

      assert %Workspace.State{} = workspace
      refute workspace.status_updated?
      assert map_size(workspace.projects) == 11
      assert length(:digraph.vertices(workspace.graph)) == 11
      assert length(:digraph.source_vertices(workspace.graph)) == 4
    end

    test "with ignore_projects set" do
      config = [
        ignore_projects: [
          PackageA.MixProject,
          PackageB.MixProject
        ]
      ]

      {:ok, workspace} = Workspace.new(@sample_workspace_path, config)

      assert %Workspace.State{} = workspace
      refute workspace.status_updated?
      assert map_size(workspace.projects) == 9
      assert length(:digraph.vertices(workspace.graph)) == 9
    end

    test "with ignore_paths set" do
      config = [
        ignore_paths: [
          "package_a",
          "package_b",
          "package_c"
        ]
      ]

      {:ok, workspace} = Workspace.new(@sample_workspace_path, config)

      assert %Workspace.State{} = workspace
      refute workspace.status_updated?
      assert map_size(workspace.projects) == 8
      assert length(:digraph.vertices(workspace.graph)) == 8
    end

    test "error if the path is not a workspace" do
      assert {:error, reason} = Workspace.new(Path.join(@sample_workspace_path, "package_a"))
      assert reason =~ "The project is not properly configured as a workspace"
      assert reason =~ "to be a workspace project. Some errors were detected"
    end

    test "error in case of an invalid path" do
      assert {:error, reason} = Workspace.new("/an/invalid/path")
      assert reason =~ "mix.exs does not exist"
      assert reason =~ "to be a workspace project. Some errors were detected"
    end

    test "raises with nested workspace" do
      message = "you are not allowed to have nested workspaces, :foo is defined as :workspace"

      assert_raise ArgumentError, message, fn ->
        project_a = project_fixture(app: :foo, workspace: [type: :workspace])
        workspace_fixture([project_a])
      end
    end

    test "error if two projects have the same name" do
      project_a = project_fixture([app: :foo], path: "packages")
      project_b = project_fixture([app: :foo], path: "tools")

      assert {:error, message} = Workspace.new("", "foo/mix.exs", [], [project_a, project_b])

      assert message == """
             You are not allowed to have multiple projects with the same name under
             the same workspace.

             * :foo is defined under: packages/foo/mix.exs, tools/foo/mix.exs
             """
    end
  end

  describe "new!/2" do
    test "error if the path is not a workspace" do
      assert_raise ArgumentError, ~r"to be a workspace project", fn ->
        Workspace.new!(Path.join(@sample_workspace_path, "package_a"))
      end
    end
  end

  describe "project/2" do
    test "gets an existing project", %{workspace: workspace} do
      assert {:ok, _project} = Workspace.project(workspace, :foo)
    end

    test "error if invalid project", %{workspace: workspace} do
      assert {:error, ":invalid is not a member of the workspace"} =
               Workspace.project(workspace, :invalid)
    end
  end

  describe "project!/2" do
    test "gets an existing project", %{workspace: workspace} do
      assert project = Workspace.project!(workspace, :foo)
      assert project.app == :foo
    end

    test "raises if invalid project", %{workspace: workspace} do
      assert_raise ArgumentError, ":invalid is not a member of the workspace", fn ->
        Workspace.project!(workspace, :invalid)
      end
    end
  end

  test "project?/2", %{workspace: workspace} do
    assert Workspace.project?(workspace, :foo)
    refute Workspace.project?(workspace, :food)
  end
end
