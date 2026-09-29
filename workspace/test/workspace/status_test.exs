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
    test "with changed file not belonging to a project", %{tmp_dir: tmp_dir} do
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

  describe "with multiple workspaces under a git root" do
    test "with changed file not belonging to a project" do
      tmp_dir = Path.join(Workspace.TestUtils.tmp_path(), "multiple_workspaces_in_git_root")
      File.mkdir_p!(tmp_dir)

      Workspace.Test.in_fixture(tmp_dir, fn ->
        Workspace.Test.init_git_project(tmp_dir)

        # add two workspaces there, one nested
        workspace_path = Path.join(tmp_dir, "workspace")
        another_workspace_path = Path.join(tmp_dir, "nested/another_workspace")

        Workspace.Test.create_workspace(
          workspace_path,
          [],
          [
            {:bar, "packages/bar", []},
            {:foo, "packages/foo", [deps: [{:bar, [path: "../bar"]}]]}
          ],
          workspace_module: "SomeTestWorkspace"
        )

        Workspace.Test.create_workspace(
          another_workspace_path,
          [],
          [
            {:other_bar, "packages/bar", []},
            {:other_foo, "packages/foo", [deps: [{:other_bar, [path: "../bar"]}]]}
          ],
          workspace_module: "AnotherTestWorkspace"
        )

        Workspace.Test.commit_changes(tmp_dir)

        # modify both workspaces
        Workspace.Test.modify_project(workspace_path, "packages/foo")
        Workspace.Test.modify_project(another_workspace_path, "packages/bar")

        workspace = Workspace.new!(workspace_path)
        another_workspace = Workspace.new!(another_workspace_path)

        # the changed files should include the changed project, with paths relative to
        # the git root, the changed file of the other workspace should be under `nil`
        assert Workspace.Status.changed(workspace) == %{
                 nil: [{"nested/another_workspace/packages/bar/lib/file.ex", :untracked}],
                 foo: [{"workspace/packages/foo/lib/file.ex", :untracked}]
               }

        assert Workspace.Status.modified(workspace) == [:foo]
        assert Workspace.Status.affected(workspace) == [:foo]

        ## another_workspace
        assert Workspace.Status.changed(another_workspace) == %{
                 bar: [{"nested/another_workspace/packages/bar/lib/file.ex", :untracked}],
                 nil: [{"workspace/packages/foo/lib/file.ex", :untracked}]
               }

        assert Workspace.Status.modified(another_workspace) == [:bar]
        assert Workspace.Status.affected(another_workspace) == [:bar, :foo]
      end)
    end
  end

  @tag :tmp_dir
  test "force update resets the previous statuses", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [
        {:foo, "foo", [deps: [{:bar, path: "../bar"}]]},
        {:bar, "bar", []}
      ],
      fn ->
        Workspace.Test.modify_project(tmp_dir, "bar")

        workspace = Workspace.new!(tmp_dir) |> Workspace.Status.update()
        assert workspace.projects[:bar].status == :modified
        assert workspace.projects[:bar].changes == [{"bar/lib/file.ex", :untracked}]
        assert workspace.projects[:foo].status == :affected

        # revert the change
        File.rm!(Path.join(tmp_dir, "bar/lib/file.ex"))

        workspace = Workspace.Status.update(workspace, force: true)
        assert workspace.projects[:bar].status == :undefined
        assert workspace.projects[:bar].changes == nil
        assert workspace.projects[:foo].status == :undefined
      end,
      git: true
    )
  end

  describe "affected_by paths" do
    @tag :tmp_dir
    test "marks project as affected when affected_by files change", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [
          {:package_a, "package_a", [workspace: [affected_by: ["../shared/config.ex"]]]},
          {:package_b, "package_b", [workspace: [affected_by: ["../docs/*.md"]]]}
        ],
        fn ->
          # Create shared files
          shared_dir = Path.join(tmp_dir, "shared")
          File.mkdir_p!(shared_dir)
          File.write!(Path.join(shared_dir, "config.ex"), "# config")

          workspace = Workspace.new!(tmp_dir)
          refute workspace.status_updated?

          # Modify shared config file
          File.write!(Path.join(shared_dir, "config.ex"), "# updated config")

          workspace = Workspace.Status.update(workspace, [])
          assert workspace.status_updated?

          # package_a should be affected due to shared/config.ex change
          assert workspace.projects[:package_a].status == :affected
          # package_b should be unaffected
          assert workspace.projects[:package_b].status == :undefined

          docs_dir = Path.join(tmp_dir, "docs")
          File.mkdir_p!(docs_dir)
          File.write!(Path.join(docs_dir, "README.md"), "# docs")

          workspace = Workspace.Status.update(workspace, force: true)
          assert workspace.status_updated?

          # package_b should be affected due to docs/*.md change
          assert workspace.projects[:package_b].status == :affected
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "supports wildcard patterns in affected_by", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [
          {:package_a, "package_a", [workspace: [affected_by: ["../shared/*.ex"]]]}
        ],
        fn ->
          # Create shared files
          shared_dir = Path.join(tmp_dir, "shared")
          File.mkdir_p!(shared_dir)

          File.write!(Path.join(shared_dir, "config.txt"), "# config")

          workspace = Workspace.new!(tmp_dir)
          refute workspace.status_updated?

          # should not be affected by a *.txt change
          assert workspace.projects[:package_a].status == :undefined

          # Modify .ex file in shared (should match)
          File.write!(Path.join(shared_dir, "utils.ex"), "# updated utils")

          workspace = Workspace.Status.update(workspace, force: true)
          assert workspace.status_updated?

          # package_a should be affected
          assert workspace.projects[:package_a].status == :affected
        end,
        git: true
      )
    end
  end

  @tag :tmp_dir
  test "affected_by changes propagate and are recorded", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [
        {:nif, "nif", [workspace: [affected_by: ["../native/common"]]]},
        {:api, "api", [deps: [{:nif, path: "../nif"}]]},
        {:other, "other", [workspace: [affected_by: ["../native/common/"]]]},
        {:unrelated, "unrelated", []}
      ],
      fn ->
        File.mkdir_p!(Path.join(tmp_dir, "native/common"))
        File.write!(Path.join(tmp_dir, "native/common/lib.rs"), "// lib")
        File.write!(Path.join(tmp_dir, "other/lib.ex"), "# lib")

        workspace = Workspace.new!(tmp_dir) |> Workspace.Status.update()
        [common] = workspace.projects[:nif].affected_by

        # the project declaring the path is affected and the change is recorded
        assert workspace.projects[:nif].status == :affected

        assert workspace.projects[:nif].affected_by_changes == [
                 {common, [{"native/common/lib.rs", :untracked}]}
               ]

        # dependents are affected as well
        assert workspace.projects[:api].status == :affected
        assert workspace.projects[:api].affected_by_changes == nil

        # modified projects remain modified
        assert workspace.projects[:other].status == :modified

        assert workspace.projects[:other].affected_by_changes == [
                 {common, [{"native/common/lib.rs", :untracked}]}
               ]

        assert workspace.projects[:unrelated].status == :undefined
        assert workspace.projects[:unrelated].affected_by_changes == nil

        assert Workspace.Status.changed_paths(workspace) == [common]
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "detects changes in a workspace under a symlinked path", %{tmp_dir: tmp_dir} do
    real_path = Path.join(tmp_dir, "real")
    link_path = Path.join(tmp_dir, "link")
    File.mkdir_p!(real_path)
    File.ln_s!(real_path, link_path)

    Workspace.Test.with_workspace(
      link_path,
      [],
      [
        {:foo, "foo", [workspace: [affected_by: ["../shared"]]]},
        {:bar, "bar", []}
      ],
      fn ->
        Workspace.Test.modify_project(link_path, "bar")
        File.mkdir_p!(Path.join(link_path, "shared"))
        File.write!(Path.join(link_path, "shared/config.exs"), "[]")

        workspace = Workspace.new!(link_path) |> Workspace.Status.update()

        assert workspace.git_root_path == link_path
        assert workspace.projects[:bar].status == :modified
        assert workspace.projects[:foo].status == :affected
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "deleted files match affected_by wildcards", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [
        {:package_a, "package_a", [workspace: [affected_by: ["../native/**/*.rs"]]]}
      ],
      fn ->
        File.mkdir_p!(Path.join(tmp_dir, "native/src"))
        File.write!(Path.join(tmp_dir, "native/src/lib.rs"), "// lib")
        Workspace.Test.commit_changes(tmp_dir)

        workspace = Workspace.new!(tmp_dir)
        workspace = Workspace.Status.update(workspace, force: true)
        assert workspace.projects[:package_a].status == :undefined

        File.rm!(Path.join(tmp_dir, "native/src/lib.rs"))

        workspace = Workspace.Status.update(workspace, force: true)
        assert workspace.projects[:package_a].status == :affected
      end,
      git: true
    )
  end

  @tag :tmp_dir
  test "supports parent directory in affected_by", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [
        {:package_a, "package_a", [workspace: [affected_by: ["../shared"]]]}
      ],
      fn ->
        workspace = Workspace.new!(tmp_dir)
        workspace = Workspace.Status.update(workspace, force: true)

        assert workspace.projects[:package_a].status == :undefined

        # Create shared files
        shared_dir = Path.join(tmp_dir, "shared")
        File.mkdir_p!(shared_dir)

        File.write!(Path.join(shared_dir, "config.txt"), "# config")

        workspace = Workspace.Status.update(workspace, force: true)
        assert workspace.projects[:package_a].status == :affected
      end,
      git: true
    )
  end
end
