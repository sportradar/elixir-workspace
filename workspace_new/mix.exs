for path <- :code.get_path(),
    Regex.match?(~r/workspace_new\-\d+\.\d+\.\d\/ebin$/, List.to_string(path)) do
  Code.delete_path(path)
end

defmodule WorkspaceNew.MixProject do
  use Mix.Project

  def project do
    [
      app: :workspace_new,
      description: "workspace generator",
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      preferred_cli_env: [docs: :docs],
      docs: docs(),
      test_coverage: [
        export: "workspace_new",
        output: "../artifacts/coverdata/workspace_new"
      ],
      package: [
        maintainers: ["Panagiotis Nezis"],
        files: ~w(lib template mix.exs README.md)
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:eex]
    ]
  end

  defp deps do
    [
      {:ex_doc, "== 0.31.2", only: :docs}
    ]
  end

  defp docs do
    [
      output: "../artifacts/docs/workspace_new",
      formatters: ["html"],
      extras: [
        "README.md": [title: "Overview"]
      ]
    ]
  end
end
