defmodule Package.MixProject do
  use Mix.Project

  # The next two lines required only for the tests
  Code.put_compiler_option(:ignore_module_conflict, true)
  Code.require_file("../../../../lib/workspace_config.ex", __DIR__)

  @app :package
  @version "0.2.0"

  @config_path WorkspaceConfig.config_path()
  @deps_path WorkspaceConfig.deps_path()
  @build_path WorkspaceConfig.build_path()
  @lockfile WorkspaceConfig.lockfile()
  @my_weird_artifacts  WorkspaceConfig.append_to_artifacts_path("child_directory")

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      elixirc_options: [ignore_module_conflict: true],
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      config_path: @config_path,
      deps_path: @deps_path,
      build_path: @build_path,
      lockfile: @lockfile,
      my_weird_artifacts: @my_weird_artifacts,
      aliases: aliases(),
      workspace: [
        tags: [{:scope, :app}]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    []
  end

  defp aliases do
    [
      dummy: &dummy/1,
      workspace_config: &workspace_config/1,
      workspace_project_config: &workspace_project_config/1,
      get_workspace_option: &get_workspace_option/1,
      workspace_root: &workspace_root/1,
      append_to_workspace_root: &append_to_workspace_root/1,
      artifacts_path: &artifacts_path/1
    ]
  end

  defp dummy(_opts), do: info("Dummy output")

  defp workspace_config(_opts) do
    WorkspaceConfig.workspace_config()
    |> info()
  end

  defp workspace_project_config(_opts) do
    Mix.Project.config()
    |> info()
  end

  defp get_workspace_option(_opts) do
    WorkspaceConfig.get_workspace_option([:workspace, :type])
    |> info()
  end

  defp workspace_root(_opts) do
    WorkspaceConfig.workspace_root()
    |> info()
  end

  defp append_to_workspace_root(_opts) do
    ["a", "long", "long", "path", "to", "nowhere"]
    |> WorkspaceConfig.append_to_workspace_root()
    |> info()
  end

  defp artifacts_path(_opts) do
    WorkspaceConfig.artifacts_path()
    |> info()
  end

  defp info(data) do
    data
    |> :erlang.term_to_binary()
    |> Base.encode64(padding: false)
    # |> inspect()
    |> Mix.Shell.IO.info()
  end
end
