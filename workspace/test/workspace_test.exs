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

  # describe "config/1" do
  #   test "warning with invalid file" do
  #     assert capture_io(:stderr, fn ->
  #              config = Workspace.config("invalid.exs")
  #              assert config == []
  #            end) =~ "file not found"
  #   end
  #
  #   test "with incorrect contents" do
  #     assert capture_io(:stderr, fn ->
  #              config = Workspace.config("test/fixtures/configs/invalid_contents.exs")
  #              # TODO: check why config is empty in this case and not the default
  #              assert config == []
  #            end) =~ "unknown options [:invalid], valid options are:"
  #   end
  #
  #   test "with valid config" do
  #     config = Workspace.config("test/fixtures/configs/valid.exs")
  #     assert is_list(config)
  #     assert config[:ignore_projects] == [Dummy.MixProject, Foo.MixProject]
  #     assert config[:ignore_paths] == ["path/to/foo"]
  #   end
  # end
  #
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
