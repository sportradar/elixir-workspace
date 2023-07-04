ExUnit.start()

# Checks related helper functions
defmodule CheckTest.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import CheckTest.Case
    end
  end

  def check_result(results, %Workspace.Project{app: app}) do
    check_result(results, app)
  end

  def check_result(results, app) when is_atom(app) do
    Enum.find(results, fn result -> result.project.app == app end)
  end

  def assert_check_status(results, project, status) do
    result = check_result(results, project)
    assert result.status == status
  end

  def assert_check_meta(results, project, meta) do
    result = check_result(results, project)
    assert result.meta == meta
  end

  def assert_formatted_result(results, project, expected) do
    result = check_result(results, project)
    assert result.module.format_result(result) == expected
  end

  def project_fixture(config, opts \\ []) do
    workspace_path = Keyword.get(opts, :workspace_path, "/usr/local/workspace")
    path = Keyword.get(opts, :path, "packages")

    app = Keyword.fetch!(config, :app)
    project_path = Path.join([workspace_path, path, Atom.to_string(app)])

    %Workspace.Project{
      app: app,
      module: project_module(app),
      config: config,
      mix_path: Path.join(project_path, "mix.exs"),
      path: project_path,
      workspace_path: workspace_path
    }
  end

  def workspace_fixture(projects, opts \\ []) do
    workspace_path = Keyword.get(opts, :workspace_path, "/usr/local/workspace")

    %Workspace{
      projects: projects,
      config: [],
      mix_path: Path.join(workspace_path, "mix.exs"),
      workspace_path: workspace_path,
      cwd: File.cwd!()
    }
  end

  defp project_module(app) do
    (Macro.camelize(Atom.to_string(app)) <> ".MixProject")
    |> String.to_atom()
  end
end
