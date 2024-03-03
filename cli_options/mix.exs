defmodule CliOptions.MixProject do
  use Mix.Project

  @app :cli_options
  @version "0.1.0"
  @description "An opinionated cli options parser"

  def project do
    [
      app: @app,
      version: @version,
      description: @description,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      deps: deps(),
      test_coverage: [
        export: "cli_options",
        output: "../artifacts/coverdata"
      ],
      docs: [
        output: "../artifacts/docs/cli_options",
        formatters: ["html"]
      ]
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    []
  end
end
