defmodule Mix.Tasks.Workspace.StatusTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.Status, as: StatusTask

  @sample_workspace_default_path Path.join(
                                   Workspace.TestUtils.tmp_path(),
                                   "sample_workspace_default"
                                 )
  @sample_workspace_changed_path Path.join(
                                   Workspace.TestUtils.tmp_path(),
                                   "sample_workspace_changed"
                                 )
  @sample_workspace_committed_path Path.join(
                                     Workspace.TestUtils.tmp_path(),
                                     "sample_workspace_committed"
                                   )

  @sample_workspace_no_git_path Path.join(
                                  Workspace.TestUtils.tmp_path(),
                                  "sample_workspace_no_git"
                                )

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  test "if no git repo" do
    message =
      "status related operations require a git repo, " <>
        "../../workspace_test_fixtures/sample_workspace_no_git is not a valid git repo"

    assert_raise Mix.Error, message, fn ->
      StatusTask.run(["--workspace-path", @sample_workspace_no_git_path])
    end
  end

  test "with no changed files" do
    expected = ""

    assert capture_io(fn ->
             StatusTask.run(["--workspace-path", @sample_workspace_default_path])
           end) == expected
  end

  test "with affected and modified files" do
    expected = """
    Modified projects:
      :package_changed_d package_changed_d/mix.exs
        untracked package_changed_d/tmp.exs
      :package_changed_e package_changed_e/mix.exs
        untracked package_changed_e/file.ex

    Affected projects:
      :package_changed_a package_changed_a/mix.exs
      :package_changed_c package_changed_c/mix.exs
      :package_changed_h package_changed_h/mix.exs

    """

    assert capture_io(fn ->
             StatusTask.run(["--workspace-path", @sample_workspace_changed_path])
           end) == expected
  end

  test "with --base and --head set" do
    expected = """
    Modified projects:
      :package_committed_c package_committed_c/mix.exs
        modified  package_committed_c/file.ex

    Affected projects:
      :package_committed_a package_committed_a/mix.exs

    """

    assert capture_io(fn ->
             StatusTask.run([
               "--workspace-path",
               @sample_workspace_committed_path,
               "--base",
               "HEAD~1",
               "--head",
               "HEAD"
             ])
           end) == expected
  end
end
