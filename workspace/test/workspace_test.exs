defmodule WorkspaceTest do
  use ExUnit.Case
  import TestUtils
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

      assert %Workspace{} = workspace
      assert map_size(workspace.projects) == 11
    end

    test "with ignore_projects set" do
      config = [
        ignore_projects: [
          PackageA.MixProject,
          PackageB.MixProject
        ]
      ]

      {:ok, workspace} = Workspace.new(@sample_workspace_path, config)

      assert %Workspace{} = workspace
      assert map_size(workspace.projects) == 9
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

      assert %Workspace{} = workspace
      assert map_size(workspace.projects) == 8
    end

    test "error if the path is not a workspace" do
      assert {:error, reason} = Workspace.new(Path.join(@sample_workspace_path, "package_a"))
      assert reason =~ "workspace option is set in config object"
      assert reason =~ "to be a workspace project. Some errors were detected"
    end
  end

  describe "new!/2" do
    test "error if the path is not a workspace" do
      assert_raise ArgumentError, ~r"to be a workspace project", fn ->
        Workspace.new!(Path.join(@sample_workspace_path, "package_a"))
      end
    end
  end

  describe "filter/2" do
    test "filters and updates the given workspace", %{workspace: workspace} do
      workspace = Workspace.filter(workspace, ignore: [:bar])

      assert workspace.projects[:bar].skip
      refute workspace.projects[:foo].skip
    end

    test "if app in ignore skips the project", %{workspace: workspace} do
      workspace = Workspace.filter(workspace, ignore: ["bar"])

      assert Workspace.project_by_app_name(workspace, :bar).skip
      refute Workspace.project_by_app_name(workspace, :foo).skip
    end

    test "if app in selected it is not skipped - everything else is skipped", %{
      workspace: workspace
    } do
      workspace = Workspace.filter(workspace, project: ["bar"])

      refute Workspace.project_by_app_name(workspace, :bar).skip
      assert Workspace.project_by_app_name(workspace, :foo).skip
    end

    test "ignore has priority over project", %{
      workspace: workspace
    } do
      workspace = Workspace.filter(workspace, ignore: [:bar], project: [:bar])

      assert Workspace.project_by_app_name(workspace, :bar).skip
      assert Workspace.project_by_app_name(workspace, :foo).skip
    end
  end
end
