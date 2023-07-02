defmodule Workspace.Checks.ValidateConfigPathTest do
  use CheckTest.Case
  alias Workspace.Checks.ValidateConfigPath

  setup do
    {:ok, check} =
      Workspace.Check.validate(
        module: ValidateConfigPath,
        opts: [
          config_attribute: :a_path,
          expected_path: "artifacts/test"
        ]
      )

    %{check: check}
  end

  test "error if config variable is not set", %{check: check} do
    workspace = single_project_workspace(app: :foo)
    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    expected = [
      "expected ",
      :light_cyan,
      ":a_path ",
      :reset,
      "to be ",
      :light_cyan,
      "../../artifacts/test",
      :reset,
      ", got: ",
      :light_cyan,
      "nil"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "error if config variable is not correctly configured", %{check: check} do
    workspace = single_project_workspace(app: :foo, a_path: "foo/bar")
    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :error)

    expected = [
      "expected ",
      :light_cyan,
      ":a_path ",
      :reset,
      "to be ",
      :light_cyan,
      "../../artifacts/test",
      :reset,
      ", got: ",
      :light_cyan,
      "foo/bar"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  test "ok if variable is properly configured", %{check: check} do
    workspace = single_project_workspace(app: :foo, a_path: "../../artifacts/test")
    results = ValidateConfigPath.check(workspace, check)

    assert_check_status(results, :foo, :ok)

    expected = [
      :light_cyan,
      ":a_path ",
      :reset,
      "is set to ",
      :light_cyan,
      "../../artifacts/test"
    ]

    assert_formatted_result(results, :foo, expected)
  end

  defp single_project_workspace(config) do
    workspace_path = "/usr/local/workspace"
    project_path = Path.join([workspace_path, "packages", Atom.to_string(config[:app])])

    project = %Workspace.Project{
      app: config[:app],
      module: ProjectModule,
      config: config,
      mix_path: Path.join(project_path, "mix.exs"),
      path: project_path,
      workspace_path: workspace_path
    }

    %Workspace{
      projects: [project],
      config: [],
      mix_path: Path.join(workspace_path, "mix.exs"),
      workspace_path: workspace_path,
      cwd: File.cwd!()
    }
  end
end
