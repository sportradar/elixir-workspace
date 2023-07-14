defmodule Mix.Tasks.Workspace.Test.CoverageTest do
  use MixTest.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Workspace.Test.Coverage, as: TestCoverageTask
  alias Mix.Tasks.Workspace.Run, as: RunTask

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)

    # on_exit(fn ->
    #   Application.put_env(:elixir, :ansi_enabled, true)
    # end)
  end

  test "run tests and analyze coverage" do
    fixture_path = test_fixture_path()

    # TODO: create another helper macro like create_fixture
    in_fixture("test_coverage", fn ->
      nil
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
    assert File.exists?(Path.join([fixture_path, "package_a", "cover", "package_a.coverdata"]))

    # check test coverage task output
    captured =
      capture_io(fn ->
        TestCoverageTask.run(["--workspace-path", fixture_path])
      end)

    expected = [
      "==> importing cover results",
      "==> :package_a - importing cover results from package_a/cover/package_a.coverdata",
      "==> :package_b - importing cover results from package_b/cover/package_b.coverdata",
      "==> :package_c - importing cover results from package_c/cover/package_c.coverdata",
      "==> analysing coverage data",
      "==> :package_a - total coverage 100.00% [threshold 90%]",
      "==> :package_b - total coverage 100.00% [threshold 90%]",
      "==> :package_c - total coverage 100.00% [threshold 90%]",
      "==> workspace coverage 100.00% [threshold 90%]"
    ]

    assert_cli_output_match(captured, expected)

    # with a single project param set
    captured =
      capture_io(fn ->
        TestCoverageTask.run(["--workspace-path", fixture_path, "--project", "package_a"])
      end)

    expected = [
      "==> importing cover results",
      "==> :package_a - importing cover results from package_a/cover/package_a.coverdata",
      "==> analysing coverage data",
      "==> :package_a - total coverage 100.00% [threshold 90%]",
      "==> workspace coverage 100.00% [threshold 90%]"
    ]

    assert_cli_output_match(captured, expected)

    # with an ignore project set
    captured =
      capture_io(fn ->
        TestCoverageTask.run(["--workspace-path", fixture_path, "--ignore", "package_a"])
      end)

    expected = [
      "==> importing cover results",
      "==> :package_b - importing cover results from package_b/cover/package_b.coverdata",
      "==> :package_c - importing cover results from package_c/cover/package_c.coverdata",
      "==> analysing coverage data",
      "==> :package_b - total coverage 100.00% [threshold 90%]",
      "==> :package_c - total coverage 100.00% [threshold 90%]",
      "==> workspace coverage 100.00% [threshold 90%]"
    ]

    assert_cli_output_match(captured, expected)
  end
end
