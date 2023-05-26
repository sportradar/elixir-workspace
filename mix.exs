defmodule Workspace.MixWorkspace do
  use Mix.Project

  def project do
    [
      app: :workspace_workspace,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: [],
      deps: deps(),
      aliases: aliases(),
      workspace: workspace()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:workspace, path: "workspace"}
    ]
  end

  defp aliases do
    [
      format: ["workspace.run -t format"]
    ]
  end

  # The workspace config
  defp workspace do
    [
      required_deps: [
        [
          dep: {:ex_doc, "~> 0.28", only: :dev, runtime: false},
          ignore: demo_projects()
        ],
        [
          dep: {:credo, "~> 1.6.7", only: [:dev, :test], runtime: false},
          ignore: demo_projects()
        ],
        [
          dep: {:doctor, "~> 0.21.0", only: :dev, runtime: false},
          ignore: demo_projects()
        ]
      ]
    ]
  end


  defp demo_projects, do: [:project_a, :project_b, :project_c, :project_d, :project_e, :project_f, :project_g, :project_h, :project_i, :project_j, :project_k]
end
