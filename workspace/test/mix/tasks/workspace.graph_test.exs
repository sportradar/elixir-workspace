defmodule Mix.Tasks.Workspace.GraphTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.Graph, as: GraphTask

  @sample_workspace_default_path Path.join(TestUtils.tmp_path(), "sample_workspace_default")
  @sample_workspace_changed_path Path.join(TestUtils.tmp_path(), "sample_workspace_changed")

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end


  test "prints the tree of the workspace" do
    expected = """
    :package_default_a
    ├── :package_default_b
    │   └── :package_default_g
    ├── :package_default_c
    │   ├── :package_default_e
    │   └── :package_default_f
    │       └── :package_default_g
    └── :package_default_d
    :package_default_h
    └── :package_default_d
    :package_default_i
    └── :package_default_j
    :package_default_k
    """

    assert capture_io(fn ->
             GraphTask.run(["--workspace-path", @sample_workspace_default_path])
           end) == expected
  end

  test "prints the tree with project statuses" do
    expected = """
    :package_changed_a ●
    ├── :package_changed_b ✔
    │   └── :package_changed_g ✔
    ├── :package_changed_c ●
    │   ├── :package_changed_e ✚
    │   └── :package_changed_f ✔
    │       └── :package_changed_g ✔
    └── :package_changed_d ✚
    :package_changed_h ●
    └── :package_changed_d ✚
    :package_changed_i ✔
    └── :package_changed_j ✔
    :package_changed_k ✔
    """

    assert capture_io(fn ->
             GraphTask.run(["--workspace-path", @sample_workspace_changed_path, "--show-status"])
           end) == expected
  end
end
