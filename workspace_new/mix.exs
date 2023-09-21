defmodule WorkspaceNew.MixProject do
  use Mix.Project

  def project do
    [
      app: :workspace_new,
      description: "Workspace generator",
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: [],
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      docs: [
        output: "../artifacts/docs/workspace_new",
        formatters: ["html"]
      ],
      test_coverage: [
        export: "workspace_new",
        output: "../artifacts/coverdata"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:eex]
    ]
  end
end
