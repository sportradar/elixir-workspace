defmodule Workspace.StatusTest do
  use ExUnit.Case

  @sample_workspace_no_git_path Path.join(
                                  Workspace.TestUtils.tmp_path(),
                                  "sample_workspace_no_git"
                                )
  @sample_workspace_changed_path Path.join(
                                   Workspace.TestUtils.tmp_path(),
                                   "sample_workspace_changed"
                                 )

  describe "update/2" do
    test "returns all changed files per project" do
      workspace = Workspace.new!(@sample_workspace_changed_path)
      refute workspace.status_updated?

      workspace = Workspace.Status.update(workspace, [])
      assert workspace.status_updated?

      assert workspace.projects[:package_changed_a].status == :affected
      assert workspace.projects[:package_changed_b].status == :undefined
      assert workspace.projects[:package_changed_c].status == :affected
      assert workspace.projects[:package_changed_d].status == :modified
      assert workspace.projects[:package_changed_e].status == :modified
      assert workspace.projects[:package_changed_f].status == :undefined
      assert workspace.projects[:package_changed_g].status == :undefined
      assert workspace.projects[:package_changed_h].status == :affected
      assert workspace.projects[:package_changed_i].status == :undefined
      assert workspace.projects[:package_changed_j].status == :undefined
      assert workspace.projects[:package_changed_k].status == :undefined

      assert workspace.projects[:package_changed_d].changes == [
               {"package_changed_d/tmp.exs", :untracked}
             ]

      assert workspace.projects[:package_changed_e].changes == [
               {"package_changed_e/file.ex", :untracked}
             ]
    end
  end

  describe "changed/2" do
    test "returns all changed files per project" do
      workspace = Workspace.new!(@sample_workspace_changed_path)

      assert Workspace.Status.changed(workspace) == %{
               package_changed_d: [{"package_changed_d/tmp.exs", :untracked}],
               package_changed_e: [{"package_changed_e/file.ex", :untracked}]
             }
    end
  end

  describe "modified/2" do
    test "returns the modified files" do
      workspace = Workspace.new!(@sample_workspace_changed_path)

      assert Workspace.Status.modified(workspace) == [:package_changed_d, :package_changed_e]
    end

    test "error if modified files cannot be retrieved" do
      workspace = Workspace.new!(@sample_workspace_no_git_path)

      assert_raise ArgumentError, ~r"failed to get changed files", fn ->
        Workspace.Status.modified(workspace)
      end
    end
  end

  describe "affected/2" do
    test "returns the affected files" do
      workspace = Workspace.new!(@sample_workspace_changed_path)

      assert Workspace.Status.affected(workspace) == [
               :package_changed_a,
               :package_changed_c,
               :package_changed_d,
               :package_changed_e,
               :package_changed_h
             ]
    end

    test "error if modified files cannot be retrieved" do
      workspace = Workspace.new!(@sample_workspace_no_git_path)

      assert_raise ArgumentError, ~r"failed to get changed files", fn ->
        Workspace.Status.affected(workspace)
      end
    end
  end
end
