defmodule Mix.Tasks.Workspace.CheckTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  # TODO: this is used in many places, add helper function to get
  # fixtures path and project
  @sample_workspace_path "test/fixtures/sample_workspace"

  test "raises if no checks are defined" do
    assert_raise Mix.Error, ~r/No checkers config found/, fn ->
      Mix.Tasks.Workspace.Check.run(["--workspace-path", @sample_workspace_path])
    end
  end

  test "runs all configured checks" do
    assert capture_io(fn ->
             Mix.Tasks.Workspace.Check.run([
               "--workspace-path",
               @sample_workspace_path,
               "--config-path",
               "../configs/with_checks.exs"
             ])
           end) =~ "NOK"
  end
end
