defmodule Workspace.GitTest do
  use ExUnit.Case

  import Workspace.TestUtils

  describe "root" do
    @tag :tmp_dir
    test "gets the proper root of a git repo", %{tmp_dir: tmp_dir} do
      # fixture_path = test_fixture_path()

      File.cd!(tmp_dir, fn ->
        init_git_project()

        assert Workspace.Git.root() == {:ok, tmp_dir}

        # should return the same from subfolders
        File.mkdir("package_a")
        File.cd!("package_a")
        assert Workspace.Git.root() == {:ok, tmp_dir}
      end)

      # test with the cd flag
      assert Workspace.Git.root(cd: tmp_dir) == {:ok, tmp_dir}
    end

    test "error if not a git repo" do
      # we cannot use the standard tmp_dir here because we need a non-git folder
      tmp_dir = Path.join(Workspace.TestUtils.tmp_path(), "no_git_repo")
      File.mkdir_p!(tmp_dir)

      File.cd!(tmp_dir, fn ->
        assert {:error, message} = Workspace.Git.root()
        assert message =~ "git rev-parse --show-toplevel failed"
        assert message =~ "not a git repository"
      end)
    end
  end

  describe "changed files" do
    @tag :tmp_dir
    test "properly detects uncommitted, unstaged, changed files", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        # at least one file is needed to get the proper diff, otherwise git diff --name-only HEAD
        # returns ambiguous HEAD error
        File.touch!("mix.exs")
        init_git_project()

        # in main branch, no changes at all
        assert Workspace.Git.changed() == {:ok, []}
        assert Workspace.Git.uncommitted_files() == {:ok, []}
        assert Workspace.Git.untracked_files() == {:ok, []}

        # add a new file/modify an existing, it should be untracked
        File.mkdir("package_a")
        File.mkdir("package_b")
        File.touch!("package_a/tmp.exs")
        File.touch!("package_b/file.ex")

        assert Workspace.Git.changed() ==
                 {:ok, [{"package_a/tmp.exs", :untracked}, {"package_b/file.ex", :untracked}]}

        assert Workspace.Git.uncommitted_files() == {:ok, []}

        assert Workspace.Git.untracked_files() ==
                 {:ok, ["package_a/tmp.exs", "package_b/file.ex"]}

        # git add a file
        System.cmd("git", ~w[add package_a/tmp.exs])

        assert Workspace.Git.changed() ==
                 {:ok, [{"package_a/tmp.exs", :uncommitted}, {"package_b/file.ex", :untracked}]}

        assert Workspace.Git.uncommitted_files() == {:ok, ["package_a/tmp.exs"]}
        assert Workspace.Git.untracked_files() == {:ok, ["package_b/file.ex"]}

        # commit the file
        System.cmd("git", ~w[commit -m message])

        # if no head is set it is not considered changed
        assert Workspace.Git.changed() == {:ok, [{"package_b/file.ex", :untracked}]}
        assert Workspace.Git.uncommitted_files() == {:ok, []}
        assert Workspace.Git.untracked_files() == {:ok, ["package_b/file.ex"]}

        # if base is head it is included
        assert Workspace.Git.changed(base: "HEAD~1") ==
                 {:ok, [{"package_a/tmp.exs", :modified}, {"package_b/file.ex", :untracked}]}

        # commit the other file as well
        System.cmd("git", ~w[add package_b/file.ex])
        System.cmd("git", ~w[commit -m message])

        # with no head set and base two commits below
        assert Workspace.Git.changed(base: "HEAD~2") ==
                 {:ok, [{"package_a/tmp.exs", :modified}, {"package_b/file.ex", :modified}]}

        # with head set
        assert Workspace.Git.changed(base: "HEAD~2", head: "HEAD~1") ==
                 {:ok, [{"package_a/tmp.exs", :modified}]}

        # changed_files/3 sanity checks
        assert Workspace.Git.changed_files("HEAD~2", "HEAD") ==
                 {:ok, ["package_a/tmp.exs", "package_b/file.ex"]}

        assert Workspace.Git.changed_files("HEAD~2", "HEAD~2") ==
                 {:ok, []}

        # if a file is moved from a project to another both are changed
        System.cmd("mv", ~w[package_b/file.ex package_a/moved_file.ex])

        assert Workspace.Git.changed() ==
                 {:ok,
                  [{"package_a/moved_file.ex", :untracked}, {"package_b/file.ex", :uncommitted}]}
      end)
    end
  end
end
