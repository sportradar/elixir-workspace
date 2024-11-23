defmodule CliOptions.MixProject do
  use Mix.Project

  @app :cli_options
  @version "0.1.3"
  @description "An opinionated cli options parser"
  @repo_url "https://github.com/sportradar/elixir-workspace"

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
      docs: docs(),
      source_url: @repo_url,

      # Linters
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:nimble_options, "~> 1.1.1"},
      {:ex_doc, "== 0.35.1", only: :dev, runtime: false},
      {:fancy_fences, "~> 0.3.1", only: :dev, runtime: false},
      {:credo, "== 1.7.10", only: [:dev, :test], runtime: false},
      {:dialyxir, "== 1.4.5", only: [:dev], runtime: false},
      {:doctor, "== 0.22.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Panagiotis Nezis"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@repo_url}/blob/main/cli_options/CHANGELOG.md",
        "GitHub" => @repo_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      canonical: "http://hexdocs.pm/#{@app}",
      output: "../artifacts/docs/cli_options",
      formatters: ["html"],
      source_url_pattern: "#{@repo_url}/blob/#{@app}/v#{@version}/#{@app}/%{path}#L%{line}",
      markdown_processor:
        {FancyFences,
         [
           fences: %{
             "cli" => {FancyFences.Processors, :multi_inspect, [[format: true, iex_prefix: true]]}
           }
         ]},
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "../artifacts/plts",
      plt_local_path: "../artifacts/plts",
      plt_file: {:no_warn, "../artifacts/plts/cli_options.plt"},
      plt_add_deps: :apps_direct,
      plt_add_apps: [:mix],
      flags: [
        "-Werror_handling",
        "-Wextra_return",
        "-Wmissing_return",
        "-Wunknown",
        "-Wunderspecs"
      ]
    ]
  end
end
