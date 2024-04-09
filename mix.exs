defmodule Workspace.MixWorkspace do
  use Mix.Project

  def project do
    [
      app: :workspace_workspace,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: [],
      deps: deps(),
      deps_path: "artifacts/deps",
      build_path: "artifacts/build",
      aliases: aliases(),
      workspace: [
        type: :workspace
      ],
      preferred_cli_env: [
        "workspace.test.coverage": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cascade, path: "cascade"},
      {:workspace, path: "workspace"}
    ]
  end

  defp aliases do
    credo_config = Path.join(File.cwd!(), ".credo.exs")

    [
      format: [
        "format",
        "workspace.run -t format --modified"
      ],
      credo: [
        "workspace.run -t credo --exclude workspace_new --exclude cascade -- --config-file #{credo_config} --strict"
      ],
      # "deps.get": ["workspace.run -t deps.get"],
      test: ["workspace.run -t test -- --cover"],
      "test.coverage": ["workspace.test.coverage"]
    ]
  end
end
