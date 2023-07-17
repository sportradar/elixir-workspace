defmodule Mix.Tasks.Workspace.ListTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.List, as: ListTask

  @sample_workspace_path "test/fixtures/sample_workspace"

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)

    # on_exit(fn ->
    #   Application.put_env(:elixir, :ansi_enabled, true)
    # end)
  end

  test "prints the tree of the workspace" do
    expected = """
      * :package_a package_a
      * :package_b a dummy project package_b
      * :package_c package_c
      * :package_d package_d
      * :package_e package_e
      * :package_f package_f
      * :package_g package_g
      * :package_h package_h
      * :package_i package_i
      * :package_j package_j
      * :package_k package_k
    """

    assert capture_io(fn ->
             ListTask.run(["--workspace-path", @sample_workspace_path])
           end) == expected
  end

  test "with --project option set" do
    expected = """
      * :package_a package_a
      * :package_b a dummy project package_b
    """

    assert capture_io(fn ->
             ListTask.run([
               "--workspace-path",
               @sample_workspace_path,
               "-p",
               "package_a",
               "-p",
               "package_b"
             ])
           end) == expected
  end

  test "with --ignore option set" do
    expected = """
      * :package_b a dummy project package_b
    """

    assert capture_io(fn ->
             ListTask.run([
               "--workspace-path",
               @sample_workspace_path,
               "-p",
               "package_a",
               "-p",
               "package_b",
               "-i",
               "package_a"
             ])
           end) == expected
  end
end
