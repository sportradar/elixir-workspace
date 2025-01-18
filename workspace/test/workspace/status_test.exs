defmodule Workspace.StatusTest do
  use ExUnit.Case

  describe "update/2" do
    @tag :tmp_dir
    test "returns all changed files per project", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        :default,
        fn ->
          Workspace.Test.modify_project(tmp_dir, "package_d")
          Workspace.Test.modify_project(tmp_dir, "package_e")

          workspace = Workspace.new!(tmp_dir)
          refute workspace.status_updated?

          workspace = Workspace.Status.update(workspace, [])
          assert workspace.status_updated?

          assert workspace.projects[:package_a].status == :affected
          assert workspace.projects[:package_b].status == :undefined
          assert workspace.projects[:package_c].status == :affected
          assert workspace.projects[:package_d].status == :modified
          assert workspace.projects[:package_e].status == :modified
          assert workspace.projects[:package_f].status == :undefined
          assert workspace.projects[:package_g].status == :undefined
          assert workspace.projects[:package_h].status == :affected
          assert workspace.projects[:package_i].status == :undefined
          assert workspace.projects[:package_j].status == :undefined
          assert workspace.projects[:package_k].status == :undefined

          assert workspace.projects[:package_d].changes == [
                   {"package_d/lib/file.ex", :untracked}
                 ]

          assert workspace.projects[:package_e].changes == [
                   {"package_e/lib/file.ex", :untracked}
                 ]
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "force option", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        :default,
        fn ->
          Workspace.Test.modify_project(tmp_dir, "package_d")
          Workspace.Test.modify_project(tmp_dir, "package_e")
          workspace = Workspace.new!(tmp_dir)
          refute workspace.status_updated?

          workspace = Workspace.Status.update(workspace, [])
          assert workspace.status_updated?

          assert workspace.projects[:package_c].status == :affected
          assert workspace.projects[:package_c].changes == nil

          # make a change to a project
          foo_path = Path.join([tmp_dir, "package_c/foo.md"])
          File.write!(foo_path, "")

          # with force not set no new changes are updated
          workspace = Workspace.Status.update(workspace, [])
          assert workspace.status_updated?

          assert workspace.projects[:package_c].status == :affected
          assert workspace.projects[:package_c].changes == nil

          # with force set to true new changes are detected
          workspace = Workspace.Status.update(workspace, force: true)
          assert workspace.status_updated?

          assert workspace.projects[:package_c].status == :modified

          assert workspace.projects[:package_c].changes == [
                   {"package_c/foo.md", :untracked}
                 ]
        end,
        git: true
      )
    end
  end

  describe "changed/2" do
    @tag :tmp_dir
    test "returns all changed files per project", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        :default,
        fn ->
          Workspace.Test.modify_project(tmp_dir, "package_d")
          Workspace.Test.modify_project(tmp_dir, "package_e")
          workspace = Workspace.new!(tmp_dir)

          assert Workspace.Status.changed(workspace) == %{
                   package_d: [{"package_d/lib/file.ex", :untracked}],
                   package_e: [{"package_e/lib/file.ex", :untracked}]
                 }
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "with changed file not belonging to a projectm", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        :default,
        fn ->
          Workspace.Test.modify_project(tmp_dir, "package_d")
          Workspace.Test.modify_project(tmp_dir, "package_e")
          workspace = Workspace.new!(tmp_dir)

          foo_path = Path.join([tmp_dir, "foo.md"])
          File.write!(foo_path, "")

          assert Workspace.Status.changed(workspace) == %{
                   package_d: [{"package_d/lib/file.ex", :untracked}],
                   package_e: [{"package_e/lib/file.ex", :untracked}],
                   nil: [{"foo.md", :untracked}]
                 }
        end,
        git: true
      )
    end
  end

  describe "modified/2" do
    @tag :tmp_dir
    test "returns the modified files", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        :default,
        fn ->
          Workspace.Test.modify_project(tmp_dir, "package_d")
          Workspace.Test.modify_project(tmp_dir, "package_e")
          workspace = Workspace.new!(tmp_dir)

          assert Workspace.Status.modified(workspace) == [:package_d, :package_e]
        end,
        git: true
      )
    end

    test "error if modified files cannot be retrieved" do
      # we cannot use the standard tmp_dir here because we need a non-git folder
      tmp_dir = Path.join(Workspace.TestUtils.tmp_path(), "empty_workspace")

      Workspace.Test.with_workspace(tmp_dir, [], [], fn ->
        workspace = Workspace.new!(tmp_dir)

        assert_raise ArgumentError, ~r"failed to get changed files", fn ->
          Workspace.Status.modified(workspace)
        end
      end)
    end
  end

  describe "affected/2" do
    @tag :tmp_dir
    test "returns the affected files", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        :default,
        fn ->
          Workspace.Test.modify_project(tmp_dir, "package_d")
          Workspace.Test.modify_project(tmp_dir, "package_e")

          workspace = Workspace.new!(tmp_dir)

          assert Workspace.Status.affected(workspace) == [
                   :package_a,
                   :package_c,
                   :package_d,
                   :package_e,
                   :package_h
                 ]
        end,
        git: true
      )
    end

    test "error if modified files cannot be retrieved" do
      # we cannot use the standard tmp_dir here because we need a non-git folder
      tmp_dir = Path.join(Workspace.TestUtils.tmp_path(), "empty_workspace")

      Workspace.Test.with_workspace(tmp_dir, [], [], fn ->
        workspace = Workspace.new!(tmp_dir)

        assert_raise ArgumentError, ~r"failed to get changed files", fn ->
          Workspace.Status.affected(workspace)
        end
      end)
    end
  end
end
