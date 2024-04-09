defmodule Cascade.MixProject do
  use Mix.Project

  def project do
    [
      app: :cascade,
      version: "0.1.0",
      elixir: "~> 1.15",
      description: "generate code from templates",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      docs: docs(),
      test_coverage: [
        export: "cascade",
        output: "../artifacts/coverdata/cascade"
      ],
      package: [
        maintainers: ["Panagiotis Nezis"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cli_options, path: "../cli_options/"},
      {:ex_doc, "== 0.31.2", only: :dev, runtime: false},
      {:credo, "~> 1.6.7", [only: [:dev, :test], runtime: false]},
      {:dialyxir, "== 1.4.3", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", [only: :dev, runtime: false]}
    ]
  end

  defp docs do
    [
      main: "readme",
      output: "../artifacts/docs/cascade",
      formatters: ["html"],
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
