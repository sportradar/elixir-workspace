defmodule Mix.Tasks.Workspace.RunTest do
  use ExUnit.Case

  require Workspace.TestUtils

  import ExUnit.CaptureIO
  import Workspace.TestUtils

  alias Mix.Tasks.Workspace.Run, as: RunTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  @default_fixture_path Path.join(tmp_path(), "sample_workspace_default")

  @default_run_task [
    "-t",
    "format",
    "--workspace-path",
    @default_fixture_path,
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
        "Running task in 2 workspace projects",
        "==> :package_default_a - mix format --check-formatted mix.exs",
        "==> :package_default_b - mix format --check-formatted mix.exs"
      ])

      args = [
        "-e",
        "package_default_a",
        "-e",
        "package_default_b",
        "--dry-run" | @default_run_task
      ]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "Running task in 9 workspace projects",
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

      assert_cli_output_match(
        captured,
        [
          "Running task in 1 workspace projects",
          "==> :package_default_a - mix format --check-formatted mix.exs",
          "==> :package_default_b - skipped",
          "==> :package_default_c - skipped",
          "==> :package_default_d - skipped",
          "==> :package_default_e - skipped",
          "==> :package_default_f - skipped",
          "==> :package_default_g - skipped",
          "==> :package_default_h - skipped",
          "==> :package_default_i - skipped",
          "==> :package_default_j - skipped",
          "==> :package_default_k - skipped"
        ]
      )
    end
  end

  describe "codebase changes flags" do
    test "with affected flag only affected projects are executed" do
      # in a codebase with no changes
      captured = capture_io(fn -> RunTask.run(["--affected" | @default_run_task]) end)

      assert_cli_output_match(captured, ["No matching projects for the given options"])

      # runs only on affected projects
      captured = capture_io(fn -> RunTask.run(["--affected" | @changed_run_task]) end)

      assert_cli_output_match(
        captured,
        [
          "Running task in 5 workspace projects",
          "==> :package_changed_a - mix format --check-formatted mix.exs",
          ":package_changed_a mix format --check-formatted mix.exs succeeded [",
          "==> :package_changed_c - mix format --check-formatted mix.exs",
          ":package_changed_c mix format --check-formatted mix.exs succeeded [",
          "==> :package_changed_d - mix format --check-formatted mix.exs",
          "==> :package_changed_e - mix format --check-formatted mix.exs",
          "==> :package_changed_h - mix format --check-formatted mix.exs"
        ],
        partial: true
      )
    end

    test "with modified flag only modified flags are executed" do
      # in a codebase with no changes
      captured = capture_io(fn -> RunTask.run(["--modified" | @default_run_task]) end)

      assert_cli_output_match(captured, ["No matching projects for the given options"])

      # runs only on affected projects
      captured = capture_io(fn -> RunTask.run(["--modified" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "Running task in 2 workspace projects",
        "==> :package_changed_d - mix format --check-formatted mix.exs",
        ":package_changed_d mix format --check-formatted mix.exs succeeded [",
        "==> :package_changed_e - mix format --check-formatted mix.exs",
        ":package_changed_e mix format --check-formatted mix.exs succeeded ["
      ])
    end

    test "with root-only flag only roots are triggered" do
      # runs only on affected projects
      captured = capture_io(fn -> RunTask.run(["--only-roots" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "Running task in 4 workspace projects",
        "==> :package_changed_a - mix format --check-formatted mix.exs",
        ":package_changed_a mix format --check-formatted mix.exs succeeded [",
        "==> :package_changed_h - mix format --check-formatted mix.exs",
        ":package_changed_h mix format --check-formatted mix.exs succeeded [",
        "==> :package_changed_i - mix format --check-formatted mix.exs",
        ":package_changed_i mix format --check-formatted mix.exs succeeded [",
        "==> :package_changed_k - mix format --check-formatted mix.exs",
        ":package_changed_k mix format --check-formatted mix.exs succeeded ["
      ])
    end

    test "with root-only and affected only affected roots are triggered" do
      # runs only on affected projects
      captured =
        capture_io(fn -> RunTask.run(["--affected", "--only-roots" | @changed_run_task]) end)

      assert_cli_output_match(captured, [
        "Running task in 2 workspace projects",
        "==> :package_changed_a - mix format --check-formatted mix.exs",
        ":package_changed_a mix format --check-formatted mix.exs succeeded [",
        "==> :package_changed_h - mix format --check-formatted mix.exs",
        ":package_changed_h mix format --check-formatted mix.exs succeeded ["
      ])
    end

    test "with show-status displays the status of each project" do
      captured = capture_io(fn -> RunTask.run(["--show-status" | @changed_run_task]) end)

      assert_cli_output_match(
        captured,
        [
          "Running task in 11 workspace projects",
          "==> :package_changed_a ● - mix format --check-formatted mix.exs",
          ":package_changed_a mix format --check-formatted mix.exs succeeded [",
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
        ],
        partial: true
      )
    end

    test "on a repo with no working tree changes nothing is executed with the affected flag" do
      captured = capture_io(fn -> RunTask.run(["--affected" | @committed_run_task]) end)

      assert_cli_output_match(captured, ["No matching projects for the given options"])
    end

    test "on a repo with base and head set" do
      captured =
        capture_io(fn ->
          RunTask.run(["--affected", "--base", "HEAD~1", "--head", "HEAD" | @committed_run_task])
        end)

      assert_cli_output_match(captured, [
        "Running task in 2 workspace projects",
        "==> :package_committed_a - mix format --check-formatted mix.exs",
        ":package_committed_a mix format --check-formatted mix.exs succeeded [",
        "==> :package_committed_c - mix format --check-formatted mix.exs",
        ":package_committed_c mix format --check-formatted mix.exs succeeded ["
      ])
    end
  end

  describe "environment variables" do
    test "raises if improper configuration of environment variables" do
      args = ["-p", "package_default_a", "--verbose", "--env-var", "FOO" | @default_run_task]

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
        "--env-var",
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
        "Running task in 1 workspace projects",
        "==> :package_default_a - mix cmd echo $FOO",
        "bar",
        ":package_default_a mix cmd echo $FOO succeeded ["
      ])

      assert System.get_env("FOO") == nil
    end
  end

  describe "exit status" do
    test "if execution on a project fails the command raises" do
      args = [
        "-p",
        "package_default_a,package_default_b",
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
      failed projects - [:package_default_a, :package_default_b]
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

    test "with --early-stop set" do
      args = [
        "-p",
        "package_default_a",
        "-p",
        "package_default_b",
        "-t",
        "cmd",
        "--early-stop",
        "--workspace-path",
        Path.join(tmp_path(), "sample_workspace_default"),
        "--",
        "exit",
        "1"
      ]

      expected_message = "--early-stop is set - terminating workspace.run"

      captured =
        assert_raise_and_capture_io(Mix.Error, expected_message, fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(
        captured,
        [
          "==> :package_default_a - mix cmd exit 1",
          "** (exit) 1",
          ":package_default_a mix cmd exit 1 failed with 1"
        ],
        partial: true
      )

      refute_cli_output_match(captured, [
        "==> :package_default_b - mix cmd exit 1",
        ":package_default_b mix cmd exit 1 failed with 1"
      ])
    end

    test "with --early-stop set but no failures" do
      args = [
        "-p",
        "package_default_a",
        "-p",
        "package_default_b",
        "-t",
        "cmd",
        "--early-stop",
        "--workspace-path",
        Path.join(tmp_path(), "sample_workspace_default"),
        "--",
        "exit",
        "0"
      ]

      captured = capture_io(fn -> RunTask.run(args) end)

      assert_cli_output_match(
        captured,
        [
          "==> :package_default_a - mix cmd exit 0",
          "==> :package_default_b - mix cmd exit 0"
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
          "failed projects - [:package_default_a, :package_default_b]"
        ],
        partial: true
      )
    end
  end

  describe "partitioned runs" do
    test "no-op if --partitions is set to 1" do
      args = [
        "--partitions",
        "1",
        "--dry-run" | @default_run_task
      ]

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "Running task in 11 workspace projects",
        "==> :package_default_a - mix format --check-formatted mix.exs",
        "==> :package_default_b - mix format --check-formatted mix.exs",
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

    test "raises if --partitions is set and no env variable is present" do
      args = [
        "--partitions",
        "4",
        "--dry-run" | @default_run_task
      ]

      expected_message =
        "The WORKSPACE_RUN_PARTITION environment variable must be set to " <>
          "an integer between 1..4 when the --partitions option is set, got: nil"

      assert_raise Mix.Error, expected_message, fn -> RunTask.run(args) end
    end

    test "with --partitions and env variable set" do
      args = [
        "--partitions",
        "4",
        "--dry-run" | @default_run_task
      ]

      # partition 1
      System.put_env("WORKSPACE_RUN_PARTITION", "1")

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "Running task in 3 workspace projects",
        "==> :package_default_a - mix format --check-formatted mix.exs",
        "==> :package_default_e - mix format --check-formatted mix.exs",
        "==> :package_default_i - mix format --check-formatted mix.exs"
      ])

      # partition 2
      System.put_env("WORKSPACE_RUN_PARTITION", "2")

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "Running task in 3 workspace projects",
        "==> :package_default_b - mix format --check-formatted mix.exs",
        "==> :package_default_f - mix format --check-formatted mix.exs",
        "==> :package_default_j - mix format --check-formatted mix.exs"
      ])

      # partition 3
      System.put_env("WORKSPACE_RUN_PARTITION", "3")

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "Running task in 3 workspace projects",
        "==> :package_default_c - mix format --check-formatted mix.exs",
        "==> :package_default_g - mix format --check-formatted mix.exs",
        "==> :package_default_k - mix format --check-formatted mix.exs"
      ])

      # partition 4
      System.put_env("WORKSPACE_RUN_PARTITION", "4")

      captured =
        capture_io(fn ->
          RunTask.run(args)
        end)

      assert_cli_output_match(captured, [
        "Running task in 2 workspace projects",
        "==> :package_default_d - mix format --check-formatted mix.exs",
        "==> :package_default_h - mix format --check-formatted mix.exs"
      ])
    after
      System.delete_env("WORKSPACE_RUN_PARTITION")
    end
  end

  test "with --export option set" do
    output = Path.join(@default_fixture_path, "run.json")

    expected = """
    * exported execution results to #{output}
    """

    assert capture_io(fn ->
             RunTask.run([
               "--workspace-path",
               @default_fixture_path,
               "--task",
               "cmd",
               "--export",
               output,
               "--",
               "exit 0"
             ])
           end) =~ expected

    runs = File.read!(output) |> Jason.decode!()

    assert length(runs) == 11
  after
    File.rm!(Path.join(@default_fixture_path, "run.json"))
  end
end
