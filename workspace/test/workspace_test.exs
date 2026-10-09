defmodule WorkspaceTest do
  use ExUnit.Case
  import Workspace.TestUtils
  doctest Workspace

  setup do
    project_a = project_fixture(app: :foo)
    project_b = project_fixture(app: :bar)

    workspace = workspace_fixture([project_a, project_b])

    %{workspace: workspace}
  end

  describe "new/2" do
    @tag :tmp_dir
    test "creates a workspace struct", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
        {:ok, workspace} = Workspace.new(tmp_dir)

        assert %Workspace.State{} = workspace
        refute workspace.status_updated?
        assert map_size(workspace.projects) == 11
        assert length(:digraph.vertices(workspace.graph)) == 11
        assert length(:digraph.source_vertices(workspace.graph)) == 4
      end)
    end

    @tag :tmp_dir
    test "with ignore_projects set", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
        config = [
          ignore_projects: [
            PackageA.MixProject,
            PackageB.MixProject
          ]
        ]

        {:ok, workspace} = Workspace.new(tmp_dir, config)

        assert %Workspace.State{} = workspace
        refute workspace.status_updated?
        assert map_size(workspace.projects) == 9
        assert length(:digraph.vertices(workspace.graph)) == 9
      end)
    end

    @tag :tmp_dir
    test "with ignore_paths set", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
        config = [
          ignore_paths: [
            "package_a",
            "package_b",
            "package_c"
          ]
        ]

        {:ok, workspace} = Workspace.new(tmp_dir, config)

        assert %Workspace.State{} = workspace
        refute workspace.status_updated?
        assert map_size(workspace.projects) == 8
        assert length(:digraph.vertices(workspace.graph)) == 8
      end)
    end

    @tag :tmp_dir
    test "ignore_paths only match whole path segments", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [{:foo, "tools/foo", []}, {:bar, "tools_extra/bar", []}],
        fn ->
          {:ok, workspace} = Workspace.new(tmp_dir, ignore_paths: ["tools"])

          assert Map.keys(workspace.projects) == [:bar]
        end
      )
    end

    @tag :tmp_dir
    test "error if the path is not a workspace", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
        assert {:error, reason} = Workspace.new(Path.join(tmp_dir, "package_a"))
        assert reason =~ "The project is not properly configured as a workspace"
        assert reason =~ "to be a workspace project. Some errors were detected"
      end)
    end

    test "error in case of an invalid path" do
      assert {:error, reason} = Workspace.new("/an/invalid/path")
      assert reason =~ "mix.exs does not exist"
      assert reason =~ "to be a workspace project. Some errors were detected"
    end

    test "raises with nested workspace" do
      message = "you are not allowed to have nested workspaces, :foo is defined as :workspace"

      assert_raise ArgumentError, message, fn ->
        project_a = project_fixture(app: :foo, workspace: [type: :workspace])
        workspace_fixture([project_a])
      end
    end

    test "error if two projects have the same name" do
      project_a = project_fixture([app: :foo], path: "packages")
      project_b = project_fixture([app: :foo], path: "tools")

      assert {:error, message} = Workspace.new("", "foo/mix.exs", [], [project_a, project_b])

      assert message == """
             You are not allowed to have multiple projects with the same name under
             the same workspace.

             * :foo is defined under: packages/foo/mix.exs, tools/foo/mix.exs
             """
    end
  end

  describe "new/2 in a git repository" do
    @tag :tmp_dir
    test "ignored and nested projects are not detected", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [
          {:foo, "foo", []},
          {:bar, "bar", []},
          {:baz, "baz", []},
          {:nested, "foo/test/fixtures/nested", []}
        ],
        fn ->
          git!(tmp_dir, ~w[rm -r --cached --quiet bar baz])
          File.write!(Path.join(tmp_dir, ".gitignore"), "baz/\n")

          {:ok, workspace} = Workspace.new(tmp_dir)

          # bar is untracked but not ignored, baz is ignored
          assert project_names(workspace) == [:bar, :foo]
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "ignore_paths and deleted projects", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [{:foo, "foo", []}, {:bar, "tools/bar", []}, {:baz, "baz", []}],
        fn ->
          # deleted but not staged, it is still listed by git
          File.rm!(Path.join(tmp_dir, "baz/mix.exs"))

          {:ok, workspace} = Workspace.new(tmp_dir, ignore_paths: ["tools"])

          assert project_names(workspace) == [:foo]
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "workspace in a subdirectory of the repository", %{tmp_dir: tmp_dir} do
      workspace_path = Path.join(tmp_dir, "workspace")

      Workspace.Test.with_workspace(workspace_path, [], [{:foo, "foo", []}], fn ->
        Workspace.Test.create_mix_project(tmp_dir, :outside, "outside", [])
        Workspace.Test.init_git_project(tmp_dir)

        {:ok, workspace} = Workspace.new(workspace_path)

        assert project_names(workspace) == [:foo]
      end)
    end

    @tag :tmp_dir
    test "ignored workspace falls back to scanning the directories", %{tmp_dir: tmp_dir} do
      workspace_path = Path.join(tmp_dir, "workspace")

      Workspace.Test.with_workspace(workspace_path, [], [{:foo, "foo", []}], fn ->
        File.write!(Path.join(tmp_dir, ".gitignore"), "workspace/\n")
        Workspace.Test.init_git_project(tmp_dir)

        {:ok, workspace} = Workspace.new(workspace_path)

        assert project_names(workspace) == [:foo]
      end)
    end

    @tag :tmp_dir
    test "projects in submodules are detected", %{tmp_dir: tmp_dir} do
      workspace_path = Path.join(tmp_dir, "workspace")
      sub = create_repo(Path.join(tmp_dir, "sub"), :sub, "sub")

      Workspace.Test.with_workspace(
        workspace_path,
        [],
        [{:foo, "foo", []}],
        fn ->
          git!(workspace_path, ["submodule", "add", "--quiet", sub, "libs"])
          git!(workspace_path, ~w[commit --quiet -m submodule])

          {:ok, workspace} = Workspace.new(workspace_path)

          assert project_names(workspace) == [:foo, :sub]
          assert workspace.projects[:sub].path == Path.join(workspace_path, "libs/sub")
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "projects in nested submodules are detected", %{tmp_dir: tmp_dir} do
      workspace_path = Path.join(tmp_dir, "workspace")

      # outer has a project and inner as a submodule
      inner = create_repo(Path.join(tmp_dir, "inner"), :inner, "inner")
      outer = create_repo(Path.join(tmp_dir, "outer"), :outer, "outer")
      git!(outer, ["submodule", "add", "--quiet", inner, "nested"])
      git!(outer, ~w[commit --quiet -m nested])

      Workspace.Test.with_workspace(
        workspace_path,
        [],
        [{:foo, "foo", []}],
        fn ->
          git!(workspace_path, ["submodule", "add", "--quiet", outer, "libs"])
          git!(workspace_path, ~w[submodule update --quiet --init --recursive])
          git!(workspace_path, ~w[commit --quiet -m submodule])

          {:ok, workspace} = Workspace.new(workspace_path)

          assert project_names(workspace) == [:foo, :inner, :outer]
          assert workspace.projects[:inner].path == Path.join(workspace_path, "libs/nested/inner")
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "uninitialized submodules are skipped with a warning", %{tmp_dir: tmp_dir} do
      workspace_path = Path.join(tmp_dir, "workspace")
      sub = create_repo(Path.join(tmp_dir, "sub"), :sub, "sub")

      Workspace.Test.with_workspace(
        workspace_path,
        [],
        [{:foo, "foo", []}],
        fn ->
          git!(workspace_path, ["submodule", "add", "--quiet", sub, "libs"])
          git!(workspace_path, ~w[commit --quiet -m submodule])
          git!(workspace_path, ~w[submodule deinit --quiet -f libs])

          warning =
            ExUnit.CaptureIO.capture_io(:stderr, fn ->
              {:ok, workspace} = Workspace.new(workspace_path)

              assert project_names(workspace) == [:foo]
            end)

          assert warning =~ "libs is not initialized"
          assert warning =~ "git submodule update --init --recursive"
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "projects in nested repositories are detected unless ignored", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [{:foo, "foo", []}],
        fn ->
          # a repository in a repository, and an ignored one
          create_repo(Path.join(tmp_dir, "repos/bar"), :bar, "bar")
          create_repo(Path.join(tmp_dir, "repos/bar/inner/baz"), :baz, "baz")
          create_repo(Path.join(tmp_dir, "ignored"), :ignored, "ignored")
          File.write!(Path.join(tmp_dir, ".gitignore"), "ignored/\n")

          {:ok, workspace} = Workspace.new(tmp_dir)

          assert project_names(workspace) == [:bar, :baz, :foo]
          assert workspace.projects[:baz].path == Path.join(tmp_dir, "repos/bar/inner/baz/baz")
        end,
        git: true
      )
    end

    @tag :tmp_dir
    test "nested repositories that cannot be listed are skipped", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(
        tmp_dir,
        [],
        [{:foo, "foo", []}],
        fn ->
          bar = create_repo(Path.join(tmp_dir, "bar"), :bar, "bar")
          File.write!(Path.join(bar, ".git/index"), "corrupted")

          {:ok, workspace} = Workspace.new(tmp_dir)

          assert project_names(workspace) == [:foo]
        end,
        git: true
      )
    end
  end

  # a git repository with a project under project_path
  defp create_repo(path, app, project_path) do
    Workspace.Test.create_mix_project(path, app, project_path, [])
    Workspace.Test.init_git_project(path)

    path
  end

  defp project_names(workspace), do: workspace.projects |> Map.keys() |> Enum.sort()

  # local repositories are used as submodules, which are not allowed by default
  defp git!(path, args) do
    {output, 0} =
      System.cmd("git", ["-c", "protocol.file.allow=always" | args],
        cd: path,
        stderr_to_stdout: true
      )

    output
  end

  describe "new!/2" do
    @tag :tmp_dir
    test "error if the path is not a workspace", %{tmp_dir: tmp_dir} do
      Workspace.Test.with_workspace(tmp_dir, [], :default, fn ->
        assert_raise ArgumentError, ~r"to be a workspace project", fn ->
          Workspace.new!(Path.join(tmp_dir, "package_b"))
        end
      end)
    end
  end

  describe "project/2" do
    test "gets an existing project", %{workspace: workspace} do
      assert {:ok, _project} = Workspace.project(workspace, :foo)
    end

    test "error if invalid project", %{workspace: workspace} do
      assert {:error, ":invalid is not a member of the workspace"} =
               Workspace.project(workspace, :invalid)
    end
  end

  describe "project!/2" do
    test "gets an existing project", %{workspace: workspace} do
      assert project = Workspace.project!(workspace, :foo)
      assert project.app == :foo
    end

    test "raises if invalid project", %{workspace: workspace} do
      assert_raise ArgumentError, ":invalid is not a member of the workspace", fn ->
        Workspace.project!(workspace, :invalid)
      end
    end
  end

  test "project?/2", %{workspace: workspace} do
    assert Workspace.project?(workspace, :foo)
    refute Workspace.project?(workspace, :food)
  end

  test "projects/1 with order set" do
    zoo =
      Workspace.Test.project_fixture(:zoo, "zoo",
        deps: [{:foo, path: "../foo"}, {:bar, path: "../bar"}]
      )

    foo = Workspace.Test.project_fixture(:foo, "foo", deps: [{:baz, path: "../baz"}])
    bar = Workspace.Test.project_fixture(:bar, "bar", deps: [{:baz, path: "../baz"}])
    baz = Workspace.Test.project_fixture(:baz, "baz", deps: [])

    workspace = Workspace.Test.workspace_fixture([zoo, foo, bar, baz])

    # without any order the response is not deterministic, we just check that we get all expected projects
    assert Workspace.projects(workspace) |> Enum.count() == 4

    # alphabetical order
    assert Workspace.projects(workspace, order: :alphabetical) |> Enum.map(& &1.app) == [
             :bar,
             :baz,
             :foo,
             :zoo
           ]

    # postorder, again the response is not deterministic but the order should
    # respect the graph topology
    projects =
      Workspace.projects(workspace, order: :postorder) |> Enum.map(& &1.app) |> Enum.with_index()

    assert [{:baz, 0} | _rest] = projects
    assert projects[:bar] < projects[:zoo]
    assert projects[:foo] < projects[:zoo]
  end
end
