defmodule ProjectA.MixProject do
  use Mix.Project

  def project do
    [
      app: :project_a,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:project_b, path: "../project_b/"},
      {:project_c, path: "../project_c/"},
      {:project_d, path: "../project_d/"},
      {:ex_doc, "~> 0.28", [only: :dev, runtime: false]}
    ]
  end
end
