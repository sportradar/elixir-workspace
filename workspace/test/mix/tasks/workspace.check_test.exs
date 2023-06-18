defmodule Mix.Tasks.Workspace.CheckTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  # TODO: this is used in many places, add helper function to get
  # fixtures path and project
  @sample_workspace_path "test/fixtures/sample_workspace"

  setup do
    Application.put_env(:elixir, :ansi_enabled, false)
    on_exit(fn -> Application.put_env(:elixir, :ansi_enabled, true) end)
  end

  test "raises if no checks are defined" do
    assert_raise Mix.Error, ~r/No checkers config found/, fn ->
      Mix.Tasks.Workspace.Check.run(["--workspace-path", @sample_workspace_path])
    end
  end

  test "runs all configured checks" do
    expected = [
      "==> running 1 workspace checks on the workspace",
      "==> check deps_path - ERROR",
      "ERROR project_a - expected :deps_path to be ../deps, got: deps",
      "ERROR project_b - expected :deps_path to be ../deps, got: deps",
      "ERROR project_c - expected :deps_path to be ../deps, got: deps",
      "ERROR project_d - expected :deps_path to be ../deps, got: deps",
      "ERROR project_e - expected :deps_path to be ../deps, got: deps",
      "ERROR project_f - expected :deps_path to be ../deps, got: deps",
      "ERROR project_g - expected :deps_path to be ../deps, got: deps",
      "OK project_h - :deps_path is set to ../deps",
      "ERROR project_i - expected :deps_path to be ../deps, got: deps",
      "ERROR project_j - expected :deps_path to be ../deps, got: deps",
      "ERROR project_k - expected :deps_path to be ../deps, got: deps"
    ]

    captured =
      capture_and_split(fn ->
        Mix.Tasks.Workspace.Check.run([
          "--workspace-path",
          @sample_workspace_path,
          "--config-path",
          "../configs/with_checks.exs"
        ])
      end)

    assert captured == expected
  end

  defp capture_and_split(fun) do
    captured = capture_io(fun)

    captured
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn line -> line != "" end)
  end
end
