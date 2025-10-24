defmodule Workspace.MixWorkspace do
  use Mix.Project

  def project do
    [
      app: :workspace_workspace,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: [],
      deps: deps(),
      deps_path: "artifacts/deps",
      build_path: "artifacts/build",
      lockfile: "workspace.lock",
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

  def cli do
    [preferred_envs: ["workspace.test.coverage": :test]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:cascade, path: "cascade"},
      {:cli_options, path: "cli_options", override: true},
      {:workspace, path: "workspace"}
    ]
  end

  defp aliases do
    [
      format: [
        "format",
        "workspace.run -t format --modified"
      ],
      test: ["workspace.run -t test --affected -- --cover"],
      "test.coverage": ["workspace.test.coverage"]
    ]
  end
end
