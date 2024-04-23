defmodule Cascade.MixProject do
  use Mix.Project

  @app :cascade
  @repo_url "https://github.com/sportradar/elixir-workspace"
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",

      # Tests
      test_coverage: [
        threshold: 100,
        export: "cascade",
        output: "../artifacts/coverdata/cascade"
      ],

      # Hex
      description: "Generate code from templates",
      package: package(),

      # Docs
      name: "Cascade",
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
      {:cli_options, path: "../cli_options/"},
      {:ex_doc, "== 0.32.0", only: :dev, runtime: false},
      {:credo, "== 1.7.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "== 1.4.3", only: [:dev], runtime: false},
      {:doctor, "== 0.21.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Panagiotis Nezis"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      canonical: "http://hexdocs.pm/#{@app}",
      output: "../artifacts/docs/cascade",
      formatters: ["html"],
      source_url_pattern: "#{@repo_url}/blob/#{@app}/v#{@version}/#{@app}/%{path}#L%{line}",
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
      plt_file: {:no_warn, "../artifacts/plts/cascade"},
      plt_add_deps: :apps_direct,
      plt_add_apps: [:eex, :mix],
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
