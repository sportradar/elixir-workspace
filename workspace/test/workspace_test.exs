defmodule WorkspaceTest do
  use ExUnit.Case
  doctest Workspace

  @sample_workspace_path "test/fixtures/sample_workspace"

  describe "projects/1" do
    test "gets all projects in the given workspace path" do
      projects = Workspace.projects(workspace_path: @sample_workspace_path)

      assert length(projects) == 11
    end

    test "raises if the root is not a workspace" do
      assert_raise Mix.Error, ~r"to be a workspace project", fn ->
        Workspace.projects(workspace_path: Path.join(@sample_workspace_path, "project_a"))
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
