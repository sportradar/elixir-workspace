defmodule Workspace.MixProject do
  use Mix.Project

  @app :workspace
  @version "0.3.0"
  @repo_url "https://github.com/sportradar/elixir-workspace"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      elixirc_paths: elixirc_paths(Mix.env()),

      # Tests
      test_ignore_filters: [&String.contains?(&1, "test/fixtures/")],
      test_coverage: [
        ignore_modules: [Workspace.TestUtils],
        threshold: 97,
        export: "workspace",
        output: "../artifacts/coverdata/workspace"
      ],

      # Hex
      description: "Tools for managing elixir mono-repos",
      package: package(),

      # Docs
      name: "Workspace",
      docs: docs(),
      source_url: @repo_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :tools]
    ]
  end

  defp package do
    [
      maintainers: ["Panagiotis Nezis"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @repo_url,
        "Changelog" =>
          "https://github.com/sportradar/elixir-workspace/blob/main/workspace/CHANGELOG.md"
      }
    ]
  end

  defp deps do
    [
      # {:cli_options, path: "../cli_options/"},
      {:cli_options, "~> 0.1.4"},
      {:nimble_options, "~> 1.1.1"},
      {:jason, "~> 1.4.1", optional: true},
      {:ex_doc, "== 0.39.1", only: :dev, runtime: false},
      {:credo, "== 1.7.13", only: [:dev, :test], runtime: false},
      {:doctor, "== 0.22.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      canonical: "http://hexdocs.pm/#{@app}",
      output: "../artifacts/docs/workspace",
      formatters: ["html"],
      source_url_pattern: "#{@repo_url}/blob/#{@app}/v#{@version}/#{@app}/%{path}#L%{line}",
      before_closing_body_tag: &before_closing_body_tag/1,
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ],
      groups_for_modules: [
        Workspace: [
          Workspace,
          Workspace.Config,
          Workspace.Filtering,
          Workspace.Graph,
          Workspace.Graph.Formatter,
          Workspace.Project,
          Workspace.State,
          Workspace.Status,
          Workspace.Topology
        ],
        "Check APIs": [
          Workspace.Check,
          Workspace.Check.Result
        ],
        Checks: [
          ~r"Workspace.Checks.*"
        ],
        Utilities: [
          Workspace.Cli,
          Workspace.Export,
          Workspace.Git,
          Workspace.Utils
        ],
        "Test Coverage": [
          Workspace.Coverage.Exporter,
          Workspace.Coverage.LCOV
        ],
        Testing: [
          Workspace.Test
        ]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script>
      function mermaidLoaded() {
        document.addEventListener("DOMContentLoaded", function () {
          mermaid.initialize({
            startOnLoad: false,
            theme: document.body.className.includes("dark") ? "dark" : "default"
          });
          let id = 0;
          for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
            const preEl = codeEl.parentElement;
            const graphDefinition = codeEl.textContent;
            const graphEl = document.createElement("div");
            const graphId = "mermaid-graph-" + id++;
            mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
              graphEl.innerHTML = svg;
              bindFunctions?.(graphEl);
              preEl.insertAdjacentElement("afterend", graphEl);
              preEl.remove();
            });
          }
      }
    </script>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js" onload="mermaidLoaded();"></script>
    """
  end

  defp before_closing_body_tag(:epub), do: ""
end
