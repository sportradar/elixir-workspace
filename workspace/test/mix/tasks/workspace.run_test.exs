defmodule Mix.Tasks.Workspace.RunTest do
  use ExUnit.Case

  require TestUtils

  import ExUnit.CaptureIO
  import TestUtils

  alias Mix.Tasks.Workspace.Run, as: RunTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  @default_run_task [
    "-t",
    "format",
    "--workspace-path",
    Path.join(tmp_path(), "sample_workspace_default"),
    "--",
    "--check-formatted",
    "mix.exs"
  ]

  @changed_run_task [
    "-t",
    "format",
    "--workspace-path",
    Path.join(tmp_path(), "sample_workspace_changed"),
    "--",
    "--check-formatted",
    "mix.exs"
  ]

  @committed_run_task [
    "-t",
    "format",
    "--workspace-path",
    Path.join(tmp_path(), "sample_workspace_committed"),
    "--",
    "--check-formatted",
    "mix.exs"
  ]

  describe "sanity checks of common cli arguments" do
    test "runs only on the selected projects" do
      args = [
        "-p",
        "package_default_a",
        "-p",
        "package_default_b",
        "--dry-run" | @default_run_task
      ]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "==> :package_default_a - mix format --check-formatted mix.exs",
        "==> :package_default_b - mix format --check-formatted mix.exs"
      ])

      args = [
        "-i",
        "package_default_a",
        "-i",
        "package_default_b",
        "--dry-run" | @default_run_task
      ]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "==> :package_default_c - mix format --check-formatted mix.exs",
        "==> :package_default_d - mix format --check-formatted mix.exs",
        "==> :package_default_e - mix format --check-formatted mix.exs",
        "==> :package_default_f - mix format --check-formatted mix.exs",
        "==> :package_default_g - mix format --check-formatted mix.exs",
        "==> :package_default_h - mix format --check-formatted mix.exs",
        "==> :package_default_i - mix format --check-formatted mix.exs",
        "==> :package_default_j - mix format --check-formatted mix.exs",
        "==> :package_default_k - mix format --check-formatted mix.exs"
      ])
    end

    test "with verbose on skipped projects are reported" do
      args = ["-p", "package_default_a", "--dry-run", "--verbose" | @default_run_task]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "==> :package_default_a - mix format --check-formatted mix.exs",
        "==> format skipping package_default_b",
        "==> format skipping package_default_c",
        "==> format skipping package_default_d",
        "==> format skipping package_default_e",
        "==> format skipping package_default_f",
        "==> format skipping package_default_g",
        "==> format skipping package_default_h",
        "==> format skipping package_default_i",
        "==> format skipping package_default_j",
        "==> format skipping package_default_k"
      ])
    end
  end

  describe "codebase changes flags" do
    test "with affected flag only affected projects are executed" do
      # in a codebase with no changes
      captured = capture_io(fn -> RunTask.run(["--affected" | @default_run_task]) end)

      assert_cli_output_match(captured, [])

      # runs only on affected projects
      captured = capture_io(fn -> RunTask.run(["--affected" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "==> :package_changed_a - mix format --check-formatted mix.exs",
        "==> :package_changed_c - mix format --check-formatted mix.exs",
        "==> :package_changed_d - mix format --check-formatted mix.exs",
        "==> :package_changed_e - mix format --check-formatted mix.exs",
        "==> :package_changed_h - mix format --check-formatted mix.exs"
      ])
    end

    test "with modified flag only modified flags are executed" do
      # in a codebase with no changes
      captured = capture_io(fn -> RunTask.run(["--modified" | @default_run_task]) end)

      assert_cli_output_match(captured, [])

      # runs only on affected projects
      captured = capture_io(fn -> RunTask.run(["--modified" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "==> :package_changed_d - mix format --check-formatted mix.exs",
        "==> :package_changed_e - mix format --check-formatted mix.exs"
      ])
    end

    test "with root-only flag only roots are triggered" do
      # runs only on affected projects
      captured = capture_io(fn -> RunTask.run(["--only-roots" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "==> :package_changed_a - mix format --check-formatted mix.exs",
        "==> :package_changed_h - mix format --check-formatted mix.exs",
        "==> :package_changed_i - mix format --check-formatted mix.exs",
        "==> :package_changed_k - mix format --check-formatted mix.exs"
      ])
    end

    test "with root-only and affected only affected roots are triggered" do
      # runs only on affected projects
      captured =
        capture_io(fn -> RunTask.run(["--affected", "--only-roots" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "==> :package_changed_a - mix format --check-formatted mix.exs",
        "==> :package_changed_h - mix format --check-formatted mix.exs"
      ])
    end

    test "with show-status displays the status of each project" do
      captured = capture_io(fn -> RunTask.run(["--show-status" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "==> :package_changed_a ● - mix format --check-formatted mix.exs",
        "==> :package_changed_b ✔ - mix format --check-formatted mix.exs",
        "==> :package_changed_c ● - mix format --check-formatted mix.exs",
        "==> :package_changed_d ✚ - mix format --check-formatted mix.exs",
        "==> :package_changed_e ✚ - mix format --check-formatted mix.exs",
        "==> :package_changed_f ✔ - mix format --check-formatted mix.exs",
        "==> :package_changed_g ✔ - mix format --check-formatted mix.exs",
        "==> :package_changed_h ● - mix format --check-formatted mix.exs",
        "==> :package_changed_i ✔ - mix format --check-formatted mix.exs",
        "==> :package_changed_j ✔ - mix format --check-formatted mix.exs",
        "==> :package_changed_k ✔ - mix format --check-formatted mix.exs"
      ])
    end

    test "on a repo with no working tree changes nothing is executed with the affected flag" do
      captured = capture_io(fn -> RunTask.run(["--affected" | @committed_run_task]) end)

      assert_cli_output_match(captured, [])
    end

    test "on a repo with base and head set" do
      captured =
        capture_io(fn ->
          RunTask.run(["--affected", "--base", "HEAD~1", "--head", "HEAD" | @committed_run_task])
        end)

      assert_cli_output_match(captured, [
        "==> :package_committed_a - mix format --check-formatted mix.exs",
        "==> :package_committed_c - mix format --check-formatted mix.exs"
      ])
    end
  end

  describe "environment variables" do
    test "raises if inproper configuration of environment variables" do
      args = ["-p", "package_default_a", "--verbose", "-e", "FOO" | @default_run_task]

      expected_message =
        "invalid environment variable definition, " <>
          "it should be of the form ENV_VAR_NAME=value, got: FOO"

      assert_raise Mix.Error, expected_message, fn ->
        RunTask.run(args)
      end
    end

    test "properly sets the evn variables" do
      assert System.get_env("FOO") == nil

      args = [
        "-p",
        "package_default_a",
        "-t",
        "cmd",
        "--workspace-path",
        Path.join(tmp_path(), "sample_workspace_default"),
        "-e",
        "FOO=bar",
        "--",
        "echo",
        "$FOO"
      ]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "==> :package_default_a - mix cmd echo $FOO",
        "bar"
      ])

      assert System.get_env("FOO") == nil
    end
  end

  describe "exit status" do
    test "if execution on a project fails the command raises" do
      args = [
        "-p",
        "package_default_a",
        "-p",
        "package_default_b",
        "-t",
        "cmd",
        "--workspace-path",
        Path.join(tmp_path(), "sample_workspace_default"),
        "--",
        "exit",
        "1"
      ]

      expected_message = """
      mix workspace.run failed - errors detected in 2 executions
      failed projects - [:package_default_b, :package_default_a]
      """

      captured =
        assert_raise_and_capture_io(Mix.Error, expected_message, fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(
        captured,
        [
          "==> :package_default_a - mix cmd exit 1",
          "** (exit) 1",
          ":package_default_a mix cmd exit 1 failed with 1",
          "==> :package_default_b - mix cmd exit 1",
          "** (exit) 1",
          ":package_default_b mix cmd exit 1 failed with 1"
        ],
        partial: true
      )
    end

    test "if allow_failure is set a warning is emitted instead" do
      args = [
        "-p",
        "package_default_a",
        "-p",
        "package_default_b",
        "-t",
        "cmd",
        "--allow-failure",
        "package_default_a",
        "--allow-failure",
        "package_default_b",
        "--workspace-path",
        Path.join(tmp_path(), "sample_workspace_default"),
        "--",
        "exit",
        "1"
      ]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(
        captured,
        [
          "==> :package_default_a - mix cmd exit 1",
          "** (exit) 1",
          ":package_default_a mix cmd exit 1 failed with 1",
          "==> :package_default_b - mix cmd exit 1",
          "** (exit) 1",
          ":package_default_b mix cmd exit 1 failed with 1",
          "WARNING task failed in 2 projects but the --alow-failure flag is set",
          "failed projects - [:package_default_b, :package_default_a]"
        ],
        partial: true
      )
    end
  end

  describe "execution mode" do
    test "with in-project execution mode" do
      args = [
        "-p",
        "package_default_a",
        "-p",
        "package_default_b",
        "--execution-mode",
        "in-project" | @default_run_task
      ]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        ":package_default_a - mix format --check-formatted mix.exs",
        ":package_default_b - mix format --check-formatted mix.exs"
      ])
    end

    test "raises with invalid execution mode" do
      args = ["--execution-mode", "invalid" | @default_run_task]

      expected_message =
        "invalid execution mode invalid, only `process` and `in-project` are supported"

      assert_raise_and_capture_io(Mix.Error, expected_message, fn ->
        RunTask.run(args)
      end)
    end
  end
end
