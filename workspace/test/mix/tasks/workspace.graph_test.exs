defmodule Mix.Tasks.Workspace.GraphTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.Graph, as: GraphTask

  @sample_workspace_path "test/fixtures/sample_workspace"

  test "prints the tree of the workspace" do
    expected = """
    :package_a
    ├── :package_b
    │   └── :package_g
    ├── :package_c
    │   ├── :package_e
    │   └── :package_f
    │       └── :package_g
    └── :package_d
    :package_h
    └── :package_d
    :package_i
    └── :package_j
    :package_k
    """

    assert capture_io(fn ->
             GraphTask.run(["--workspace-path", @sample_workspace_path])
           end) == expected
  end
end
