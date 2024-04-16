defmodule Workspace.MixProject do
  use Mix.Project

  @app :workspace
  @version "0.1.0"
  @repo_url "https://github.com/pnezis/workspace"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      elixirc_paths: elixirc_paths(Mix.env()),

      # Tests
      test_coverage: [
        threshold: 98,
        export: "workspace",
        output: "../artifacts/coverdata/workspace"
      ],

      # Hex
      description: "Tools for managing elixir mono-repos",
      package: package(),

      # Docs
      name: "Workspace",
      docs: docs(),

      # Linters
      dialyzer: [plt_add_apps: [:mix]]
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
      maintainers: ["Panagiotis Nezis"]
    ]
  end

  defp deps do
    [
      {:cli_options, path: "../cli_options/"},
      {:nimble_options, "== 1.1.0"},
      {:jason, "~> 1.4.1", optional: true},
      {:ex_doc, "== 0.32.0", only: :dev, runtime: false},
      {:credo, "== 1.7.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "== 1.4.3", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      output: "../artifacts/docs/workspace",
      formatters: ["html"],
      source_url_pattern: "#{@repo_url}/blob/#{@app}/v#{@version}/#{@app}/%{path}#L%{line}",
      before_closing_body_tag: &before_closing_body_tag/1,
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"]
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
        ]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
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
      });
    </script>
    """
  end

  defp before_closing_body_tag(:epub), do: ""
end
