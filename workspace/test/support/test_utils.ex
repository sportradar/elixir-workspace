defmodule TestUtils do
  @moduledoc false

  # creates a simple project fixture
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

  # creates a workspace fixture
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

  # Get a single project by name
  def project_by_name(projects, name) do
    case Enum.filter(projects, fn project -> project.app == name end) do
      [project] -> project
      _ -> raise ArgumentError, "no project with the given name #{name}"
    end
  end
end
