defmodule Workspace.MixProject do
  use Mix.Project

  def project do
    [
      app: :workspace,
      description: "tooling for managing elixir mono-repos",
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      package: [
        maintainers: ["Panagiotis Nezis"]
      ],
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      dialyzer: [plt_add_apps: [:mix]],
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [
        export: "workspace",
        output: "../artifacts/coverdata/workspace"
      ],
      docs: [
        output: "../artifacts/docs/workspace",
        formatters: ["html"],
        before_closing_body_tag: &before_closing_body_tag/1,
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
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cli_options, path: "../cli_options/"},
      {:nimble_options, "~> 1.0.2"},
      {:jason, "~> 1.4.1", optional: true},
      {:ex_doc, "== 0.31.2", only: :dev, runtime: false},
      {:credo, "~> 1.6.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "== 1.4.3", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
