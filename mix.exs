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
    credo_config = Path.join(File.cwd!(), ".credo.exs")

    [
      "workspace.format": [
        "format",
        "workspace.run -t format"
      ],
      credo: [
        "workspace.run -t credo -- --config-file #{credo_config} --strict"
      ],
      # "deps.get": ["workspace.run -t deps.get"],
      test: ["workspace.run -t test"]
    ]
  end
end
