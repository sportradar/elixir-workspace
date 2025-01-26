defmodule Mix.Tasks.Workspace.CheckTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Workspace.TestUtils

  alias Mix.Tasks.Workspace.Check, as: CheckTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  @tag :tmp_dir
  test "raises if no checks are defined", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(tmp_dir, [], [], fn ->
      assert_raise Mix.Error, ~r/No checks configured in your workspace/, fn ->
        CheckTask.run(["--workspace-path", tmp_dir])
      end
    end)
  end

  @tag :tmp_dir
  test "runs all configured checks", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = [
          "running 4 workspace checks on the workspace",
          "==> C000 deps_path check deps_path",
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
          "==> C001 fail_b fail on package b",
          "WARN  :package_b - invalid package",
          "==> C002 always_fails always fails",
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
          "==> C003 never_fails never fails"
        ]

        captured =
          assert_raise_and_capture_io(
            Mix.Error,
            ~r"mix workspace.check failed - errors detected in 1 checks",
            fn ->
              CheckTask.run([
                "--workspace-path",
                tmp_dir,
                "--config-path",
                Path.expand("../../fixtures/configs/with_checks.exs", __DIR__)
              ])
            end
          )

        assert_cli_output_match(captured, expected)
      end,
      projects: [package_h: [deps_path: "../deps"]]
    )
  end

  @tag :tmp_dir
  test "with --check flag runs only selected checks", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = [
          "running 2 workspace checks on the workspace",
          "==> C000 deps_path check deps_path",
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
          "==> C003 never_fails never fails"
        ]

        captured =
          assert_raise_and_capture_io(
            Mix.Error,
            ~r"mix workspace.check failed - errors detected in 1 checks",
            fn ->
              CheckTask.run([
                "--workspace-path",
                tmp_dir,
                "--config-path",
                Path.expand("../../fixtures/configs/with_checks.exs", __DIR__),
                "-c",
                "deps_path",
                "-c",
                "never_fails"
              ])
            end
          )

        assert_cli_output_match(captured, expected)
      end,
      projects: [package_h: [deps_path: "../deps"]]
    )
  end

  @tag :tmp_dir
  test "with --verbose flag on", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      :default,
      fn ->
        expected = [
          "running 4 workspace checks on the workspace",
          "==> C000 deps_path check deps_path",
          "ERROR :package_a - expected :deps_path to be ../deps, got: deps",
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
          "==> C001 fail_b fail on package b",
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
          "==> C002 always_fails always fails",
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
          "==> C003 never_fails never fails",
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
                tmp_dir,
                "--config-path",
                Path.expand("../../fixtures/configs/with_checks.exs", __DIR__),
                "--verbose",
                "--exclude",
                "package_d"
              ])
            end
          )

        assert_cli_output_match(captured, expected)
      end,
      projects: [package_h: [deps_path: "../deps"]]
    )
  end

  @tag :tmp_dir
  test "with check groups", %{tmp_dir: tmp_dir} do
    Workspace.Test.with_workspace(
      tmp_dir,
      [],
      [{:foo, "packages/foo", []}, {:bar, "packages/bar", []}],
      fn ->
        expected = """
        running 4 workspace checks on the workspace
        ==> C000 deps_path all projects must have a common deps_path set

        ## Documentation checks
        ==> C001 docs_output_path all projects must have a common docs output path
        ==> C002 source_url all projects must have the same source_url set

        ## Testing checks
        ==> C003 coverage all projects must have coverage threshold of at least 90%
        """

        captured =
          capture_io(fn ->
            CheckTask.run([
              "--workspace-path",
              tmp_dir,
              "--config-path",
              Path.expand("../../fixtures/configs/check_groups.exs", __DIR__)
            ])
          end)

        Workspace.Test.assert_captured(captured, expected,
          trim_trailing_newlines: true,
          trim_whitespace: true
        )
      end
    )
  end
end
