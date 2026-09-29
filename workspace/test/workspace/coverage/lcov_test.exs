defmodule Workspace.Coverage.LCOVTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @tag :tmp_dir
  test "export/3 output paths", %{tmp_dir: tmp_dir} do
    workspace = Workspace.Test.workspace_fixture([], workspace_path: tmp_dir)

    # by default it is exported under cover relative to the workspace root
    capture_io(fn -> Workspace.Coverage.LCOV.export(workspace, []) end)
    assert File.exists?(Path.join(tmp_dir, "cover/coverage.lcov"))

    # absolute paths are used as is
    output_path = Path.join(tmp_dir, "absolute")

    capture_io(fn ->
      Workspace.Coverage.LCOV.export(workspace, [], output_path: output_path, filename: "ws.lcov")
    end)

    assert File.exists?(Path.join(output_path, "ws.lcov"))
  end
end
