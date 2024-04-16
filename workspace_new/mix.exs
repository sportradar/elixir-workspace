for path <- :code.get_path(),
    Regex.match?(~r/workspace_new\-\d+\.\d+\.\d\/ebin$/, List.to_string(path)) do
  Code.delete_path(path)
end

defmodule WorkspaceNew.MixProject do
  use Mix.Project

  def project do
    [
      app: :workspace_new,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      preferred_cli_env: [docs: :docs],

      # Tests
      test_coverage: [
        threshold: 100,
        export: "workspace_new",
        output: "../artifacts/coverdata/workspace_new"
      ],

      # Hex
      description: "A mix task for scaffolding empty workspace projects",
      package: package(),

      # Docs
      name: "WorkspaceNew",
      docs: docs()
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
      {:ex_doc, "== 0.32.0", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Panagiotis Nezis"],
      files: ~w(lib template mix.exs README.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      output: "../artifacts/docs/workspace_new",
      formatters: ["html"],
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
