defmodule Mix.Tasks.Workspace.CheckTest do
  use ExUnit.Case, async: false
  import Workspace.TestUtils

  alias Mix.Tasks.Workspace.Check, as: CheckTask

  @sample_workspace_path fixture_path(:sample_workspace)

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  test "raises if no checks are defined" do
    assert_raise Mix.Error, ~r/No checks configured in your workspace/, fn ->
      CheckTask.run(["--workspace-path", @sample_workspace_path])
    end
  end

  test "runs all configured checks" do
    expected = [
      "running 4 workspace checks on the workspace",
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
      "ERROR :package_k - expected :deps_path to be ../../deps, got: deps",
      "==> C001 fail on package b",
      "WARN  :package_b - invalid package",
      "==> C002 always fails",
      "WARN  :package_a - this always fails",
      "WARN  :package_b - this always fails",
      "WARN  :package_c - this always fails",
      "WARN  :package_d - this always fails",
      "WARN  :package_e - this always fails",
      "WARN  :package_f - this always fails",
      "WARN  :package_g - this always fails",
      "WARN  :package_h - this always fails",
      "WARN  :package_i - this always fails",
      "WARN  :package_j - this always fails",
      "WARN  :package_k - this always fails",
      "==> C003 never fails"
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

  test "with --verbose flag on" do
    expected = [
      "running 4 workspace checks on the workspace",
      "==> C000 check deps_path",
      "ERROR :package_a - expected :deps_path to be ../deps, got: deps test/fixtures/sample_workspace/package_a",
      "ERROR :package_b - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_c - expected :deps_path to be ../deps, got: deps",
      "SKIP  :package_d - check skipped",
      "ERROR :package_e - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_f - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_g - expected :deps_path to be ../deps, got: deps",
      "OK    :package_h - :deps_path is set to ../deps",
      "ERROR :package_i - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_j - expected :deps_path to be ../deps, got: deps",
      "ERROR :package_k - expected :deps_path to be ../../deps, got: deps",
      "==> C001 fail on package b",
      "OK    :package_a - no error",
      "WARN  :package_b - invalid package",
      "OK    :package_c - no error",
      "SKIP  :package_d - check skipped",
      "OK    :package_e - no error",
      "OK    :package_f",
      "OK    :package_g - no error",
      "OK    :package_h - no error",
      "OK    :package_i - no error",
      "OK    :package_j - no error",
      "OK    :package_k - no error",
      "==> C002 always fails",
      "WARN  :package_a - this always fails",
      "WARN  :package_b - this always fails",
      "WARN  :package_c - this always fails",
      "SKIP  :package_d - check skipped",
      "WARN  :package_e - this always fails",
      "WARN  :package_f - this always fails",
      "WARN  :package_g - this always fails",
      "WARN  :package_h - this always fails",
      "WARN  :package_i - this always fails",
      "WARN  :package_j - this always fails",
      "WARN  :package_k - this always fails",
      "==> C003 never fails",
      "OK    :package_a - never fails",
      "OK    :package_b - never fails",
      "OK    :package_c - never fails",
      "SKIP  :package_d - check skipped",
      "OK    :package_e - never fails",
      "OK    :package_f - never fails",
      "OK    :package_g - never fails",
      "OK    :package_h - never fails",
      "OK    :package_i - never fails",
      "OK    :package_j - never fails",
      "OK    :package_k - never fails"
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
            "../configs/with_checks.exs",
            "--verbose",
            "--exclude",
            "package_d"
          ])
        end
      )

    assert_cli_output_match(captured, expected)
  end
end
