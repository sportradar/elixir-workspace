defmodule Workspace.StatusTest do
  use ExUnit.Case

  @sample_workspace_no_git_path Path.join(TestUtils.tmp_path(), "sample_workspace_no_git")
  @sample_workspace_changed_path Path.join(TestUtils.tmp_path(), "sample_workspace_changed")

  describe "modified/2" do
    test "returns the modified files" do
      workspace = Workspace.new!(@sample_workspace_changed_path)

      assert Workspace.Status.modified(workspace) == [:package_changed_d, :package_changed_e]
    end

    test "error if modified files cannot be retrieved" do
      workspace = Workspace.new!(@sample_workspace_no_git_path)

      assert_raise ArgumentError, fn -> Workspace.Status.modified(workspace) end
    end
  end

  describe "affected/2" do
    test "returns the affected files" do
      workspace = Workspace.new!(@sample_workspace_changed_path)

      assert Workspace.Status.affected(workspace) == [
               :package_changed_c,
               :package_changed_a,
               :package_changed_h,
               :package_changed_d,
               :package_changed_e
             ]
    end

    test "error if modified files cannot be retrieved" do
      workspace = Workspace.new!(@sample_workspace_no_git_path)

      assert_raise ArgumentError, fn -> Workspace.Status.affected(workspace) end
    end
  end
end
