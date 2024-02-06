defmodule Workspace.Checks.DependenciesVersionTest do
  use Workspace.CheckCase
  alias Workspace.Checks.DependenciesVersion

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        module: DependenciesVersion,
        opts: [
          deps: [
            {:foo, "== 0.1", only: :dev},
            {:bar, "== 0.2", only: :dev, no_options_check: true},
            {:baz, "== 0.3", only: :dev, no_options_check: [:package_a]},
            {:ban, "== 0.4"},
            {:git, github: "test/test"}
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

    expected_package_a = [
      "all dependencies versions match the expected ones"
    ]

    assert_formatted_result(results, :package_a, expected_package_a)

    expected_package_b = [
      "version mismatches for the following dependencies: ",
      :yellow,
      "[:foo, :baz]",
      :reset,
      "\n",
      "    → ",
      :yellow,
      ":foo",
      :reset,
      " expected ",
      :light_cyan,
      "{\"== 0.1\", [only: :dev], []}",
      :reset,
      " got ",
      :light_cyan,
      "{\"== 0.1\", [only: :test]}",
      :reset,
      "\n",
      "    → ",
      :yellow,
      ":baz",
      :reset,
      " expected ",
      :light_cyan,
      "{\"== 0.3\", [only: :dev], [no_options_check: [:package_a]]}",
      :reset,
      " got ",
      :light_cyan,
      "{\"== 0.3\", [only: :test]}",
      :reset
    ]

    assert_formatted_result(results, :package_b, expected_package_b)

    expected_package_c = [
      "version mismatches for the following dependencies: ",
      :yellow,
      "[:ban]",
      :reset,
      "\n",
      "    → ",
      :yellow,
      ":ban",
      :reset,
      " expected ",
      :light_cyan,
      "{\"== 0.4\", [], []}",
      :reset,
      " got ",
      :light_cyan,
      "{\"== 0.3\", []}",
      :reset
    ]

    assert_formatted_result(results, :package_c, expected_package_c)

    expected_package_d = [
      "version mismatches for the following dependencies: ",
      :yellow,
      "[:git]",
      :reset,
      "\n",
      "    → ",
      :yellow,
      ":git",
      :reset,
      " expected ",
      :light_cyan,
      "{nil, [github: \"test/test\"], []}",
      :reset,
      " got ",
      :light_cyan,
      "{nil, [branch: \"test\", github: \"test/test\"]}",
      :reset
    ]

    assert_formatted_result(results, :package_d, expected_package_d)
  end
end
