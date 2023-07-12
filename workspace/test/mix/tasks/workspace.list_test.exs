defmodule Mix.Tasks.Workspace.ListTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.List, as: ListTask

  @sample_workspace_path "test/fixtures/sample_workspace"

  test "prints the tree of the workspace" do
    expected = """
      * :project_a project_a
      * :project_b a dummy project project_b
      * :project_c project_c
      * :project_d project_d
      * :project_e project_e
      * :project_f project_f
      * :project_g project_g
      * :project_h project_h
      * :project_i project_i
      * :project_j project_j
      * :project_k project_k
    """

    assert capture_io(fn ->
             ListTask.run(["--workspace-path", @sample_workspace_path])
           end) == expected
  end

  test "with --project option set" do
    expected = """
      * :project_a project_a
      * :project_b a dummy project project_b
    """

    assert capture_io(fn ->
             ListTask.run([
               "--workspace-path",
               @sample_workspace_path,
               "-p",
               "project_a",
               "-p",
               "project_b"
             ])
           end) == expected
  end

  test "with --ignore option set" do
    expected = """
      * :project_b a dummy project project_b
    """

    assert capture_io(fn ->
             ListTask.run([
               "--workspace-path",
               @sample_workspace_path,
               "-p",
               "project_a",
               "-p",
               "project_b",
               "-i",
               "project_a"
             ])
           end) == expected
  end
end
