defmodule CliOptions.MixProject do
  use Mix.Project

  @app :cli_options
  @version "0.1.0"
  @description "An opinionated cli options parser"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      deps: deps(),

      # Tests
      test_coverage: [
        threshold: 100,
        export: "cli_options",
        output: "../artifacts/coverdata/cli_options"
      ],

      # Hex
      description: @description,
      package: package(),

      # Docs
      name: "CliOptions",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "== 0.32.0", only: :dev, runtime: false},
      {:fancy_fences, "~> 0.3.1", only: :dev, runtime: false},
      {:credo, "== 1.7.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "== 1.4.3", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Panagiotis Nezis"]
    ]
  end

  defp docs do
    [
      main: "readme",
      output: "../artifacts/docs/cli_options",
      formatters: ["html"],
      markdown_processor:
        {FancyFences,
         [
           fences: %{
             "cli" => {FancyFences.Processors, :multi_inspect, [[format: true, iex_prefix: true]]}
           }
         ]},
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
