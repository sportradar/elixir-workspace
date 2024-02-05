defmodule Mix.Tasks.Workspace.StatusTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.Status, as: StatusTask

  @sample_workspace_default_path Path.join(TestUtils.tmp_path(), "sample_workspace_default")
  @sample_workspace_changed_path Path.join(TestUtils.tmp_path(), "sample_workspace_changed")
  @sample_workspace_committed_path Path.join(TestUtils.tmp_path(), "sample_workspace_committed")

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
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
      :package_changed_e package_changed_e/mix.exs

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
