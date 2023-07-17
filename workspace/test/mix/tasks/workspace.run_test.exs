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
    Path.join(tmp_path(), "sample_workspace_run"),
    "--",
    "--check-formatted",
    "mix.exs"
  ]

  describe "sanity checks of common cli arguments" do
    test "runs only on the selected projects" do
      args = ["-p", "package_default_a", "-p", "package_default_b", "--dry-run" | @default_run_task]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "==> :package_default_a - mix format --check-formatted mix.exs",
        "==> :package_default_b - mix format --check-formatted mix.exs"
      ])

      args = ["-i", "package_default_a", "-i", "package_default_b", "--dry-run" | @default_run_task]

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
        "==> formatskipping package_default_b",
        "==> formatskipping package_default_c",
        "==> formatskipping package_default_d",
        "==> formatskipping package_default_e",
        "==> formatskipping package_default_f",
        "==> formatskipping package_default_g",
        "==> formatskipping package_default_h",
        "==> formatskipping package_default_i",
        "==> formatskipping package_default_j",
        "==> formatskipping package_default_k"
      ])
    end
  end

  describe "codebase changes flags" do
    test "with affected flag only affected projects are executed" do
    end

    test "with modified flag only modified flags are executed" do
    end

    test "with root-only flag only roots are triggered" do
    end

    test "with root-only and affected only affected roots are triggered" do
    end

    test "with show-status displays the status of each project" do
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
        Path.join(tmp_path(), "sample_workspace_run"),
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
        Path.join(tmp_path(), "sample_workspace_run"),
        "--",
        "exit",
        "1"
      ]

      expected_message = "mix workspace.run failed - errors detected in 2 executions"

      captured =
        assert_raise_and_capture_io(Mix.Error, expected_message, fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "==> :package_default_a - mix cmd exit 1",
        "** (exit) 1",
        "(mix 1.14.2) lib/mix/tasks/cmd.ex:74: Mix.Tasks.Cmd.run/1",
        "(mix 1.14.2) lib/mix/task.ex:421: anonymous fn/3 in Mix.Task.run_task/4",
        "(mix 1.14.2) lib/mix/cli.ex:84: Mix.CLI.run_task/2",
        ":package_default_a mix cmd exit 1 failed with 1",
        "==> :package_default_b - mix cmd exit 1",
        "** (exit) 1",
        "(mix 1.14.2) lib/mix/tasks/cmd.ex:74: Mix.Tasks.Cmd.run/1",
        "(mix 1.14.2) lib/mix/task.ex:421: anonymous fn/3 in Mix.Task.run_task/4",
        "(mix 1.14.2) lib/mix/cli.ex:84: Mix.CLI.run_task/2",
        ":package_default_b mix cmd exit 1 failed with 1"
      ])
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
