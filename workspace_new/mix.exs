for path <- :code.get_path(),
    Regex.match?(~r/workspace_new\-\d+\.\d+\.\d\/ebin$/, List.to_string(path)) do
  Code.delete_path(path)
end

defmodule WorkspaceNew.MixProject do
  use Mix.Project

  @app :workspace_new
  @version "0.2.0"
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
      docs: docs(),
      source_url: @repo_url
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
      {:ex_doc, "== 0.39.1", only: :dev, runtime: false},
      {:credo, "== 1.7.13", only: [:dev, :test], runtime: false},
      {:doctor, "== 0.22.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Panagiotis Nezis"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @repo_url,
        "Changelog" =>
          "https://github.com/sportradar/elixir-workspace/blob/main/workspace_new/CHANGELOG.md"
      },
      files: ~w(lib template mix.exs README.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      canonical: "http://hexdocs.pm/#{@app}",
      output: "../artifacts/docs/workspace_new",
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
end
