defmodule Mix.Tasks.Workspace.GraphTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Mix.Tasks.Workspace.Graph, as: GraphTask

  @sample_workspace_path "test/fixtures/sample_workspace"

  test "prints the tree of the workspace" do
    expected = """
    project_a
    ├── project_b
    │   └── project_g
    ├── project_c
    │   ├── project_e
    │   └── project_f
    │       └── project_g
    └── project_d
    project_h
    └── project_d
    project_i
    └── project_j
    project_k
    """

    assert capture_io(fn ->
             GraphTask.run(["--workspace-path", @sample_workspace_path])
           end) == expected
  end
end
