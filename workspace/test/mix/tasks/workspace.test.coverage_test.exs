defmodule Mix.Tasks.Workspace.Test.CoverageTest do
  use ExUnit.Case

  require TestUtils

  import ExUnit.CaptureIO
  import TestUtils

  alias Mix.Tasks.Workspace.Run, as: RunTask
  alias Mix.Tasks.Workspace.Test.Coverage, as: TestCoverageTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
  end

  test "run tests and analyze coverage" do
    fixture_path = test_fixture_path()

    in_fixture("test_coverage", fn ->
      make_fixture_unique(fixture_path, 0)
    end)

    # first run the tests with --cover flag set
    capture_io(fn ->
      RunTask.run([
        "-t",
        "test",
        "--workspace-path",
        fixture_path,
        "--",
        "--cover"
      ])
    end)

    # check that the coverdata files were created
    assert File.exists?(Path.join([fixture_path, "package_0a/cover/package_0a.coverdata"]))
    assert File.exists?(Path.join([fixture_path, "package_0b/cover/package_0b.coverdata"]))
    assert File.exists?(Path.join([fixture_path, "package_0c/cover/package_0c.coverdata"]))

    # check test coverage task output
    captured =
      assert_raise_and_capture_io(
        Mix.Error,
        ~r"coverage for one or more projects below the required threshold",
        fn ->
          TestCoverageTask.run(["--workspace-path", fixture_path])
        end
      )

    expected =
      [
        "==> importing cover results",
        "==> :package_a - importing cover results from package_a/cover/package_a.coverdata",
        "==> :package_b - importing cover results from package_b/cover/package_b.coverdata",
        "==> :package_c - importing cover results from package_c/cover/package_c.coverdata",
        "==> analysing coverage data",
        "==> :package_a - total coverage 100.00% [threshold 90%]",
        "==> :package_b - total coverage 50.00% [threshold 90%]",
        "50.00%   PackageB (1/2 lines)",
        "==> :package_c - total coverage 25.00% [threshold 90%]",
        "25.00%   PackageC (1/4 lines)",
        "==> workspace coverage 42.86% [threshold 90%]"
      ]
      |> add_index_to_output(0)

    assert_cli_output_match(captured, expected)
  end

  test "test coverage on a single project" do
    fixture_path = test_fixture_path()

    # TODO: create another helper macro like create_fixture
    in_fixture("test_coverage", fn ->
      make_fixture_unique(fixture_path, 1)
    end)

    # first run the tests with --cover flag set
    capture_io(fn ->
      RunTask.run([
        "-t",
        "test",
        "--workspace-path",
        fixture_path,
        "--",
        "--cover"
      ])
    end)

    # with a single project param set
    captured =
      capture_io(fn ->
        TestCoverageTask.run(["--workspace-path", fixture_path, "--project", "package_1a"])
      end)

    expected =
      [
        "==> importing cover results",
        "==> :package_a - importing cover results from package_a/cover/package_a.coverdata",
        "==> analysing coverage data",
        "==> :package_a - total coverage 100.00% [threshold 90%]",
        "==> workspace coverage 100.00% [threshold 90%]"
      ]
      |> add_index_to_output(1)

    assert_cli_output_match(captured, expected)
  end

  test "with verbose flag set" do
    fixture_path = test_fixture_path()

    # TODO: create another helper macro like create_fixture
    in_fixture("test_coverage", fn ->
      make_fixture_unique(fixture_path, 2)
    end)

    # first run the tests with --cover flag set
    capture_io(fn ->
      RunTask.run([
        "-t",
        "test",
        "--workspace-path",
        fixture_path,
        "-p",
        "package_2a",
        "--",
        "--cover"
      ])
    end)

    # with a single project param set
    captured =
      capture_io(fn ->
        TestCoverageTask.run([
          "--workspace-path",
          fixture_path,
          "--project",
          "package_2a",
          "--verbose"
        ])
      end)

    expected =
      [
        "==> importing cover results",
        "==> :package_a - importing cover results from package_a/cover/package_a.coverdata",
        "==> analysing coverage data",
        "==> :package_a - total coverage 100.00% [threshold 90%]",
        "100.00%  PackageA (1/1 lines)",
        "==> workspace coverage 100.00% [threshold 90%]"
      ]
      |> add_index_to_output(2)

    assert_cli_output_match(captured, expected)
  end

  test "with lcov exporter set and allow failures set" do
    fixture_path = test_fixture_path()

    in_fixture("test_coverage", fn ->
      make_fixture_unique(fixture_path, 4)
    end)

    capture_io(fn ->
      RunTask.run([
        "-t",
        "test",
        "--workspace-path",
        fixture_path,
        "--",
        "--cover"
      ])
    end)

    # with a single project param set
    captured =
      capture_io(fn ->
        TestCoverageTask.run([
          "--workspace-path",
          fixture_path,
          "--config-path",
          "workspace_with_lcov_exporter.exs"
        ])
      end)

    expected =
      [
        "==> importing cover results",
        "==> :package_a - importing cover results from package_a/cover/package_a.coverdata",
        "==> :package_b - importing cover results from package_b/cover/package_b.coverdata",
        "==> :package_c - importing cover results from package_c/cover/package_c.coverdata",
        "==> analysing coverage data",
        "==> :package_a - total coverage 100.00% [threshold 90%]",
        "==> :package_b - total coverage 50.00% [threshold 90%]",
        "50.00%   PackageB (1/2 lines)",
        "==> :package_c - total coverage 25.00% [threshold 90%]",
        "25.00%   PackageC (1/4 lines)",
        "==> workspace coverage 42.86% [threshold 40%]",
        "==> exporting coverage data",
        "saving lcov report to #{fixture_path}/coverage/coverage.lcov"
      ]
      |> add_index_to_output(4)

    assert_cli_output_match(captured, expected)
    assert File.exists?(Path.join(fixture_path, "coverage/coverage.lcov"))
  end

  test "with missing coverdata files" do
    fixture_path = test_fixture_path()

    in_fixture("test_coverage", fn ->
      make_fixture_unique(fixture_path, 3)
    end)

    # run test task to generate beams
    # TODO: handle missing beam files
    capture_io(fn ->
      RunTask.run([
        "-t",
        "test",
        "--workspace-path",
        fixture_path
      ])
    end)

    captured =
      assert_raise_and_capture_io(
        Mix.Error,
        ~r"coverage for one or more projects below the required threshold",
        fn ->
          TestCoverageTask.run(["--workspace-path", fixture_path])
        end
      )

    # TODO change format of missing coverdata
    # make it a warning and add warnings-as-arrors flag
    expected =
      [
        "==> importing cover results",
        "package_a - could not find .coverdata file in any of the paths:",
        "package_b - could not find .coverdata file in any of the paths:",
        "package_c - could not find .coverdata file in any of the paths:",
        "==> analysing coverage data",
        "==> :package_a - total coverage 0.00% [threshold 90%]",
        "0.00%    PackageA (0/1 lines)",
        "==> :package_b - total coverage 0.00% [threshold 90%]",
        "0.00%    PackageB (0/2 lines)",
        "==> :package_c - total coverage 0.00% [threshold 90%]",
        "0.00%    PackageC (0/4 lines)",
        "==> workspace coverage 0.00% [threshold 90%]"
      ]
      |> add_index_to_output(3)

    assert_cli_output_match(captured, expected)
  end

  defp add_index_to_output(lines, index) do
    Enum.map(lines, fn line ->
      line
      |> String.replace("package_", "package_#{index}")
      |> String.replace("Package", "Package#{index}")
    end)
  end
end
