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
      builg_path: "artifacts/build",
      aliases: aliases(),
      workspace: true
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
      {:workspace, path: "workspace"}
    ]
  end

  defp aliases do
    [
      "workspace.format": [
        "format",
        "workspace.run -t format"
      ],
      "deps.get": ["workspace.run -t deps.get"],
      test: ["workspace.run -t test"]
    ]
  end
end
