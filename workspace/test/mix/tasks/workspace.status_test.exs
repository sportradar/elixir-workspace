defmodule Mix.Tasks.Workspace.StatusTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Workspace.Test, only: [assert_captured: 3]

  alias Mix.Tasks.Workspace.Status, as: StatusTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  test "raises with no git repo" do
    # we cannot use the standard tmp_dir here because we need a non-git folder
    tmp_dir = Path.join(Workspace.TestUtils.tmp_path(), "no_git_repo")

    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [{:foo, "packages/foo", []}],
      fn ->
        message =
          "status related operations require a git repo, " <>
            "../../workspace_test_fixtures/no_git_repo is not a valid git repo"

        assert_raise Mix.Error, message, fn ->
          StatusTask.run(["--workspace-path", tmp_dir])
        end
      end
    )
  end

  @tag :tmp_dir
  test "supports multiple workspaces under the same root folder" do
    # we use an external tmp dir to avoid conflicts with the current git repo
    tmp_dir = Path.join(Workspace.TestUtils.tmp_path(), "multiple_workspaces")
    File.mkdir_p!(tmp_dir)

    Workspace.Test.in_fixture(tmp_dir, fn ->
      # initialize a git repository under the root folder
      Workspace.Test.init_git_project(tmp_dir)

      workspace_path = Path.join(tmp_dir, "workspace")
      another_workspace_path = Path.join(tmp_dir, "another_workspace")

      Workspace.Test.create_workspace(
        workspace_path,
        [],
        [{:bar, "packages/bar", []}, {:foo, "packages/foo", [deps: [{:bar, [path: "../bar"]}]]}],
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

      # if no file is changed
      assert capture_io(fn ->
               StatusTask.run(["--workspace-path", workspace_path])
             end) == ""

      assert capture_io(fn ->
               StatusTask.run(["--workspace-path", another_workspace_path])
             end) == ""

      # modify the two root projects in the workspaces
      Workspace.Test.modify_project(workspace_path, "packages/foo")
      Workspace.Test.modify_project(another_workspace_path, "packages/foo")

      expected = """
      Modified projects:
        :foo packages/foo/mix.exs
          untracked packages/foo/lib/file.ex
      """

      assert_captured(
        capture_io(fn ->
          StatusTask.run(["--workspace-path", workspace_path])
        end),
        expected,
        trim_trailing_newlines: true
      )

      assert_captured(
        capture_io(fn ->
          StatusTask.run(["--workspace-path", another_workspace_path])
        end),
        expected,
        trim_trailing_newlines: true
      )

      Workspace.Test.commit_changes(tmp_dir)

      Workspace.Test.modify_project(workspace_path, "packages/bar")

      Workspace.Test.modify_project(another_workspace_path, "packages/foo",
        file: "lib/another_file.ex"
      )

      expected_with_affected =
        """
        Modified projects:
          :bar packages/bar/mix.exs
            untracked packages/bar/lib/file.ex

        Affected projects:
          :foo packages/foo/mix.exs
        """

      assert_captured(
        capture_io(fn ->
          StatusTask.run(["--workspace-path", workspace_path])
        end),
        expected_with_affected,
        trim_trailing_newlines: true
      )

      expected_without_affected =
        """
        Modified projects:
          :foo packages/foo/mix.exs
            untracked packages/foo/lib/another_file.ex
        """

      assert_captured(
        capture_io(fn ->
          StatusTask.run(["--workspace-path", another_workspace_path])
        end),
        expected_without_affected,
        trim_trailing_newlines: true
      )
    end)
  end

  @tag :tmp_dir
  test "with a proper git repo", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [{:bar, "packages/bar", []}, {:foo, "packages/foo", [deps: [{:bar, [path: "../bar"]}]]}],
      fn ->
        # if no file is changed
        assert capture_io(fn ->
                 StatusTask.run(["--workspace-path", tmp_dir])
               end) == ""

        # with only a modified project - no affected dependency
        Workspace.Test.modify_project(tmp_dir, "packages/foo")

        assert_captured(
          capture_io(fn ->
            StatusTask.run(["--workspace-path", tmp_dir])
          end),
          """
          Modified projects:
            :foo packages/foo/mix.exs
              untracked packages/foo/lib/file.ex
          """,
          trim_trailing_newlines: true
        )

        # with both modified and changed
        Workspace.Test.commit_changes(tmp_dir)
        Workspace.Test.modify_project(tmp_dir, "packages/bar")

        captured = capture_io(fn -> StatusTask.run(["--workspace-path", tmp_dir]) end)

        expected =
          """
          Modified projects:
            :bar packages/bar/mix.exs
              untracked packages/bar/lib/file.ex

          Affected projects:
            :foo packages/foo/mix.exs
          """

        assert_captured(captured, expected, trim_trailing_newlines: true)

        # if the file is commited no changes are detected
        Workspace.Test.commit_changes(tmp_dir)

        assert capture_io(fn ->
                 StatusTask.run(["--workspace-path", tmp_dir])
               end) == ""

        # if we specifically set --base and --head we get the changed files
        captured =
          capture_io(fn ->
            StatusTask.run([
              "--workspace-path",
              tmp_dir,
              "--base",
              "HEAD~1",
              "--head",
              "HEAD"
            ])
          end)

        assert_captured(
          captured,
          """
          Modified projects:
            :bar packages/bar/mix.exs
              modified  packages/bar/lib/file.ex

          Affected projects:
            :foo packages/foo/mix.exs
          """,
          trim_trailing_newlines: true
        )
      end,
      git: true
    )
  end
end
