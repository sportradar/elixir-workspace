defmodule Workspace.GitTest do
  use MixTest.Case

  describe "root" do
    test "gets the proper root of a git repo" do
      fixture_path = test_fixture_path()

      in_fixture("sample_workspace", fn ->
        init_git_project()

        assert Workspace.Git.root() == {:ok, fixture_path}

        # should return the same from subfolders
        File.cd!("package_a")
        assert Workspace.Git.root() == {:ok, fixture_path}
      end)

      # test with the cd flag
      assert Workspace.Git.root(cd: fixture_path) == {:ok, fixture_path}
    end

    test "error if not a git repo" do
      in_fixture("sample_workspace", fn ->
        assert {:error, message} = Workspace.Git.root()
        assert message =~ "git rev-parse --show-toplevel failed"
        assert message =~ "not a git repository"
      end)
    end
  end

  describe "changed files" do
    test "properly detects uncommitted, unstaged, changed files" do
      in_fixture("sample_workspace", fn ->
        init_git_project()

        # in main branch, no changes at all
        assert Workspace.Git.changed_files() == {:ok, []}
        assert Workspace.Git.uncommitted_files() == {:ok, []}
        assert Workspace.Git.untracked_files() == {:ok, []}

        # add a new file/modify an existing, it should be untracked
        File.touch!("package_a/tmp.exs")
        File.touch!("package_b/file.ex")

        assert Workspace.Git.changed_files() == {:ok, ["package_a/tmp.exs", "package_b/file.ex"]}
        assert Workspace.Git.uncommitted_files() == {:ok, []}

        assert Workspace.Git.untracked_files() ==
                 {:ok, ["package_a/tmp.exs", "package_b/file.ex"]}

        # git add a file
        System.cmd("git", ~w[add package_a/tmp.exs])

        assert Workspace.Git.changed_files() == {:ok, ["package_a/tmp.exs", "package_b/file.ex"]}
        assert Workspace.Git.uncommitted_files() == {:ok, ["package_a/tmp.exs"]}

        assert Workspace.Git.untracked_files() == {:ok, ["package_b/file.ex"]}
      end)
    end
  end
end
