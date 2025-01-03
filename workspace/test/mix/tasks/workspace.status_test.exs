defmodule Mix.Tasks.Workspace.StatusTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Workspace.Test, only: [assert_captured: 3]

  alias Mix.Tasks.Workspace.Status, as: StatusTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  @tag :tmp_dir
  test "raises with no git repo", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [{:foo, "packages/foo", []}],
      fn ->
        message =
          "status related operations require a git repo, " <>
            "../../workspace_test_fixtures/no-git is not a valid git repo"

        assert_raise Mix.Error, message, fn ->
          StatusTask.run(["--workspace-path", tmp_dir])
        end
      end
    )
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
