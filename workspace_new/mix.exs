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
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      preferred_cli_env: [docs: :docs],
      docs: [
        output: "../artifacts/docs/workspace_new",
        formatters: ["html"]
      ],
      test_coverage: [
        export: "workspace_new",
        output: "../artifacts/coverdata"
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
      {:ex_doc, "== 0.30.9", only: :docs}
    ]
  end
end
