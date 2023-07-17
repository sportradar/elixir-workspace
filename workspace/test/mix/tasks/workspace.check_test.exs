defmodule Mix.Tasks.Workspace.CheckTest do
  use ExUnit.Case, async: false
  import TestUtils

  alias Mix.Tasks.Workspace.Check, as: CheckTask

  # TODO: this is used in many places, add helper function to get
  # fixtures path and project
  @sample_workspace_path "test/fixtures/sample_workspace"

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)

    # on_exit(fn ->
    #   Application.put_env(:elixir, :ansi_enabled, true)
    # end)
  end

  test "raises if no checks are defined" do
    assert_raise Mix.Error, ~r/No checkers config found/, fn ->
      CheckTask.run(["--workspace-path", @sample_workspace_path])
    end
  end

  test "runs all configured checks" do
    expected = [
      "==> running 1 workspace checks on the workspace",
      "==> C000 check deps_path",
      "ERROR :package_a - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_b - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_c - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_d - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_e - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_f - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_g - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_i - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_j - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_k - expected :deps_path to be ../deps, got: deps"
    ]

    captured =
      assert_raise_and_capture_io(
        Mix.Error,
        ~r"mix workspace.check failed - errors detected in 1 checks",
        fn ->
          CheckTask.run([
            "--workspace-path",
            @sample_workspace_path,
            "--config-path",
            "../configs/with_checks.exs"
          ])
        end
      )

    assert_cli_output_match(captured, expected)
  end
end
