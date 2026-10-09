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

        # the prefix is the relative path within the repository
        assert Workspace.Git.prefix() == {:ok, "package_a/"}
        assert Workspace.Git.prefix(cd: tmp_dir) == {:ok, ""}
      end)

      # test with the cd flag
      assert Workspace.Git.root(cd: tmp_dir) == {:ok, tmp_dir}
    end

    @tag :tmp_dir
    test "keeps the symlinked form of the given path", %{tmp_dir: tmp_dir} do
      repo_path = Path.join(tmp_dir, "repo")
      link_path = Path.join(tmp_dir, "link")
      File.mkdir_p!(Path.join(repo_path, "package_a"))
      File.ln_s!(repo_path, link_path)

      File.cd!(repo_path, fn -> init_git_project() end)

      assert Workspace.Git.root(cd: link_path) == {:ok, link_path}
      assert Workspace.Git.root(cd: Path.join(link_path, "package_a")) == {:ok, link_path}
    end

    @tag :tmp_dir
    test "git warnings are not included in the output", %{tmp_dir: tmp_dir} do
      File.mkdir_p!(Path.join(tmp_dir, "sub"))
      File.cd!(tmp_dir, fn -> init_git_project() end)

      # deprecated config options make git print a warning on every command
      System.cmd("git", ~w[config core.fsyncObjectFiles true], cd: tmp_dir)

      assert Workspace.Git.root(cd: Path.join(tmp_dir, "sub")) == {:ok, tmp_dir}
      assert Workspace.Git.prefix(cd: Path.join(tmp_dir, "sub")) == {:ok, "sub/"}
    end

    @tag :tmp_dir
    test "symlinks with the same name as their target", %{tmp_dir: tmp_dir} do
      repo_path = Path.join(tmp_dir, "repo")
      link_path = Path.join(tmp_dir, "links/ws")
      File.mkdir_p!(Path.join(repo_path, "ws"))
      File.mkdir_p!(Path.dirname(link_path))
      File.ln_s!(Path.join(repo_path, "ws"), link_path)

      File.cd!(repo_path, fn -> init_git_project() end)

      # stripping the prefix from the link path would give links, which is not the root
      assert Workspace.Git.root(cd: link_path) == {:ok, repo_path}
    end

    @tag :tmp_dir
    test "falls back to the resolved root for symlinks into the repo", %{tmp_dir: tmp_dir} do
      repo_path = Path.join(tmp_dir, "repo")
      link_path = Path.join(tmp_dir, "link")
      File.mkdir_p!(Path.join(repo_path, "sub/workspace"))
      File.ln_s!(Path.join(repo_path, "sub/workspace"), link_path)

      File.cd!(repo_path, fn -> init_git_project() end)

      # there is no symlinked form of the root, since the link points inside the repo
      assert Workspace.Git.root(cd: link_path) == {:ok, repo_path}
    end

    test "error if not a git repo" do
      # we cannot use the standard tmp_dir here because we need a non-git folder
      tmp_dir = Path.join(Workspace.TestUtils.tmp_path(), "no_git_repo")
      File.mkdir_p!(tmp_dir)

      File.cd!(tmp_dir, fn ->
        assert {:error, message} = Workspace.Git.root()
        assert message =~ "git rev-parse --show-toplevel"
        assert message =~ "not a git repository"

        # the no commits fallback is not used outside of a repository
        assert {:error, message} = Workspace.Git.uncommitted_files()
        assert message =~ "not a git repository"
        refute message =~ "--cached"
      end)
    end
  end

  describe "submodules/1" do
    @tag :tmp_dir
    test "returns the submodules of the repository", %{tmp_dir: tmp_dir} do
      sub = Path.join(tmp_dir, "sub")
      File.mkdir_p!(sub)
      File.write!(Path.join(sub, "README.md"), "")
      File.cd!(sub, fn -> init_git_project() end)

      repo = Path.join(tmp_dir, "repo")
      File.mkdir_p!(Path.join(repo, "packages"))

      File.cd!(repo, fn ->
        init_git_project()
        assert Workspace.Git.submodules() == {:ok, []}

        for path <- ["sub", "packages/sub"] do
          {_output, 0} =
            System.cmd(
              "git",
              ~w[-c protocol.file.allow=always submodule add --quiet] ++ [sub, path],
              stderr_to_stdout: true
            )
        end

        assert Workspace.Git.submodules() == {:ok, ["packages/sub", "sub"]}
        System.cmd("git", ~w[commit --quiet -m submodules], stderr_to_stdout: true)

        # relative to the given path, uninitialized submodules are included
        System.cmd("git", ~w[submodule deinit --quiet -f sub], stderr_to_stdout: true)
        assert Workspace.Git.submodules(cd: "packages") == {:ok, ["sub"]}
        assert Workspace.Git.submodules() == {:ok, ["packages/sub", "sub"]}
      end)
    end
  end

  describe "changed files" do
    @tag :tmp_dir
    test "with base only changes since the merge base are included", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        File.touch!("mix.exs")
        init_git_project()

        System.cmd("git", ~w[checkout --quiet -b feature])
        File.touch!("feature.ex")
        System.cmd("git", ~w[add feature.ex])
        System.cmd("git", ~w[commit --quiet -m feature])

        # main moves forward after the feature branch was created
        System.cmd("git", ~w[checkout --quiet main])
        File.touch!("main.ex")
        System.cmd("git", ~w[add main.ex])
        System.cmd("git", ~w[commit --quiet -m main])
        System.cmd("git", ~w[checkout --quiet feature])

        assert Workspace.Git.changed(base: "main") == {:ok, [{"feature.ex", :modified}]}

        assert Workspace.Git.changed(base: "main", head: "feature") ==
                 {:ok, [{"feature.ex", :modified}]}
      end)
    end

    @tag :tmp_dir
    test "file names are not quoted", %{tmp_dir: tmp_dir} do
      names = ["café.ex", "quote\"d.ex", "tab\tname.ex", "back\\slash.ex", "space .ex"]

      File.cd!(tmp_dir, fn ->
        File.touch!("mix.exs")
        init_git_project()

        for name <- names, do: File.write!(name, "")
        assert Workspace.Git.untracked_files() == {:ok, Enum.sort(names)}

        System.cmd("git", ~w[add .])
        assert Workspace.Git.uncommitted_files() == {:ok, Enum.sort(names)}

        System.cmd("git", ~w[commit --quiet -m files])
        assert Workspace.Git.changed_files("HEAD~1", "HEAD") == {:ok, Enum.sort(names)}

        {:ok, files} = Workspace.Git.files()
        assert Enum.all?(names, &(&1 in files))
      end)
    end

    @tag :tmp_dir
    test "git warnings are not included in the files", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        File.write!("file.ex", "a\n")
        init_git_project()

        # git warns about the line endings of modified files
        System.cmd("git", ~w[config core.autocrlf true])
        File.write!("file.ex", "b\n")

        assert Workspace.Git.uncommitted_files() == {:ok, ["file.ex"]}
      end)
    end

    @tag :tmp_dir
    test "detects changes in a repo without any commits", %{tmp_dir: tmp_dir} do
      File.cd!(tmp_dir, fn ->
        System.cmd("git", ~w[init --quiet])

        File.touch!("staged.ex")
        File.touch!("untracked.ex")
        System.cmd("git", ~w[add staged.ex])

        assert Workspace.Git.uncommitted_files() == {:ok, ["staged.ex"]}

        assert Workspace.Git.changed() ==
                 {:ok, [{"staged.ex", :uncommitted}, {"untracked.ex", :untracked}]}
      end)
    end

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
