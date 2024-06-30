defmodule TestWorkspace.MixWorkspace do
  use Mix.Project

  @app :test_workspace
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: [],
      config_path: "config/config.exs",
      deps_path: "artifacts/deps",
      build_path: "artifacts/build",
      lockfile: "workspace.lock",
      aliases: aliases(),
      workspace: [
        type: :workspace,
        artifacts_path: "artifacts"
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
    []
  end
end
