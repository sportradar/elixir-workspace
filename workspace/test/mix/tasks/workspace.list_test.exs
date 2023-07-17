defmodule Mix.Tasks.Workspace.ListTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.List, as: ListTask

  @sample_workspace_default_path Path.join(TestUtils.tmp_path(), "sample_workspace_default")
  @sample_workspace_changed_path Path.join(TestUtils.tmp_path(), "sample_workspace_changed")

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  test "prints the tree of the workspace" do
    expected = """
      * :package_default_a package_default_a
      * :package_default_b a dummy project package_default_b
      * :package_default_c package_default_c
      * :package_default_d package_default_d
      * :package_default_e package_default_e
      * :package_default_f package_default_f
      * :package_default_g package_default_g
      * :package_default_h package_default_h
      * :package_default_i package_default_i
      * :package_default_j package_default_j
      * :package_default_k package_default_k
    """

    assert capture_io(fn ->
             ListTask.run(["--workspace-path", @sample_workspace_default_path])
           end) == expected
  end

  test "with --show-status flag" do
    expected = """
      * :package_changed_a ● package_changed_a
      * :package_changed_b ✔ a dummy project package_changed_b
      * :package_changed_c ● package_changed_c
      * :package_changed_d ✚ package_changed_d
      * :package_changed_e ✚ package_changed_e
      * :package_changed_f ✔ package_changed_f
      * :package_changed_g ✔ package_changed_g
      * :package_changed_h ● package_changed_h
      * :package_changed_i ✔ package_changed_i
      * :package_changed_j ✔ package_changed_j
      * :package_changed_k ✔ package_changed_k
    """

    assert capture_io(fn ->
             ListTask.run(["--workspace-path", @sample_workspace_changed_path, "--show-status"])
           end) == expected

  end

  test "with --project option set" do
    expected = """
      * :package_default_a package_default_a
      * :package_default_b a dummy project package_default_b
    """

    assert capture_io(fn ->
             ListTask.run([
               "--workspace-path",
               @sample_workspace_default_path,
               "-p",
               "package_default_a",
               "-p",
               "package_default_b"
             ])
           end) == expected
  end

  test "with --ignore option set" do
    expected = """
      * :package_default_b a dummy project package_default_b
    """

    assert capture_io(fn ->
             ListTask.run([
               "--workspace-path",
               @sample_workspace_default_path,
               "-p",
               "package_default_a",
               "-p",
               "package_default_b",
               "-i",
               "package_default_a"
             ])
           end) == expected
  end
end
