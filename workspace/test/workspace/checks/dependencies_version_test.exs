defmodule Workspace.Checks.DependenciesVersionTest do
  use Workspace.CheckCase
  alias Workspace.Checks.DependenciesVersion

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        id: :test_check,
        module: DependenciesVersion,
        opts: [
          deps: [
            foo: [version: "== 0.1", options: [only: :dev]],
            bar: [version: "== 0.2"],
            baz: [version: "== 0.3"],
            ban: [version: "== 0.4"],
            git: [version: [github: "test/test"]]
          ]
        ]
      )

    package_a =
      project_fixture(
        app: :package_a,
        deps: [
          {:foo, "== 0.1", only: :dev},
          {:bar, "== 0.2", only: :test},
          {:baz, "== 0.3", only: :test}
        ]
      )

    package_b =
      project_fixture(
        app: :package_b,
        deps: [
          {:foo, "== 0.1", only: :test},
          {:bar, "== 0.2", only: :test},
          {:baz, "== 0.3", only: :test}
        ]
      )

    package_c =
      project_fixture(
        app: :package_c,
        deps: [
          {:ban, "== 0.3"}
        ]
      )

    package_d =
      project_fixture(
        app: :package_d,
        deps: [
          {:git, github: "test/test", branch: "test"}
        ]
      )

    workspace = workspace_fixture([package_a, package_b, package_c, package_d])

    %{check: check, workspace: workspace}
  end

  test "properly handles dependency version mismatches", %{check: check, workspace: workspace} do
    results = DependenciesVersion.check(workspace, check)
    assert_check_status(results, :package_a, :ok)
    assert_check_status(results, :package_b, :error)
    assert_check_status(results, :package_c, :error)
    assert_check_status(results, :package_d, :error)

    assert_plain_result(results, :package_a, "all dependencies versions match the expected ones")

    expected_b = [
      "version mismatches for the following dependencies: [:foo]",
      "→ :foo expected [version: \"== 0.1\", options: [only: :dev]] got {\"== 0.1\", [only: :test]}"
    ]

    assert_plain_result(results, :package_b, expected_b)

    expected_c = [
      "version mismatches for the following dependencies: [:ban]",
      "→ :ban expected [version: \"== 0.4\"] got {\"== 0.3\", []}"
    ]

    assert_plain_result(results, :package_c, expected_c)

    expected_d = [
      "version mismatches for the following dependencies: [:git]",
      "→ :git expected [version: [github: \"test/test\"]] got {[github: \"test/test\", branch: \"test\"], []}"
    ]

    assert_plain_result(results, :package_d, expected_d)
  end
end
