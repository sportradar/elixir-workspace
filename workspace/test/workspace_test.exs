defmodule WorkspaceTest do
  use ExUnit.Case
  doctest Workspace

  @sample_workspace_path "test/fixtures/sample_workspace"

  describe "new/1" do
    test "creates a workspace struct" do
      workspace = Workspace.new(@sample_workspace_path)

      assert %Workspace{} = workspace
      assert length(workspace.projects) == 11
    end

    test "with ignore_projects set" do
      config = %Workspace.Config{
        ignore_projects: [
          ProjectA.MixProject,
          ProjectB.MixProject
        ]
      }

      workspace = Workspace.new(@sample_workspace_path, config)

      assert %Workspace{} = workspace
      assert length(workspace.projects) == 9
    end

    test "with ignore_paths set" do
      config = %Workspace.Config{
        ignore_paths: [
          "project_a",
          "project_b",
          "project_c"
        ]
      }

      workspace = Workspace.new(@sample_workspace_path, config)

      assert %Workspace{} = workspace
      assert length(workspace.projects) == 8
    end

    test "raises if the path is not a workspace" do
      assert_raise Mix.Error, ~r"to be a workspace project", fn ->
        Workspace.new(Path.join(@sample_workspace_path, "project_a"))
      end
    end
  end

  describe "workspace?/1" do
    test "relative/absolute paths to valid projects" do
      assert Workspace.workspace?(@sample_workspace_path)
      assert Workspace.workspace?(Path.expand(@sample_workspace_path))

      assert Workspace.workspace?(Path.join(@sample_workspace_path, "mix.exs"))
      assert Workspace.workspace?(Path.join(@sample_workspace_path, "mix.exs") |> Path.expand())

      refute Workspace.workspace?(Path.join(@sample_workspace_path, "project_a"))
      refute Workspace.workspace?(Path.join(@sample_workspace_path, "project_a") |> Path.expand())
    end

    test "raises if not valid project" do
      assert_raise ArgumentError, fn ->
        Workspace.workspace?(Path.join(@sample_workspace_path, "invalid"))
      end
    end

    test "with project config" do
      workspace_config =
        Path.join(@sample_workspace_path, "mix.exs") |> Workspace.Project.config()

      project_config =
        Path.join([@sample_workspace_path, "project_a", "mix.exs"]) |> Workspace.Project.config()

      assert Workspace.workspace?(workspace_config)
      refute Workspace.workspace?(project_config)
    end
  end
end
