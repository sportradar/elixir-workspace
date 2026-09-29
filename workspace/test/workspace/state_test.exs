defmodule Workspace.StateTest do
  use ExUnit.Case, async: true

  describe "git_file_path/2" do
    setup do
      workspace = Workspace.Test.workspace_fixture([])
      path = workspace.workspace_path

      %{workspace: %{workspace | git_root_path: path, git_workspace_path: path}}
    end

    test "files are relative to the git root", %{workspace: workspace} do
      assert Workspace.State.git_file_path(workspace, "foo/lib/foo.ex") ==
               "/usr/local/workspace/foo/lib/foo.ex"
    end

    test "tilde is not expanded", %{workspace: workspace} do
      assert Workspace.State.git_file_path(workspace, "~/file.ex") ==
               "/usr/local/workspace/~/file.ex"
    end
  end
end
