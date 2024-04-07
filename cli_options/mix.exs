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
      {:ex_doc, "== 0.31.2", only: :dev, runtime: false},
      {:fancy_fences, "~> 0.3.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      output: "../artifacts/docs/cli_options",
      formatters: ["html"],
      markdown_processor:
        {FancyFences,
         [
           fences: %{
             "cli" => {FancyFences.Processors, :multi_inspect, [[format: true, iex_prefix: true]]}
           }
         ]}
    ]
  end
end
