defmodule ProjectB.MixProject do
  use Mix.Project

  def project do
    [
      app: :project_b,
      version: "0.1.0",
      elixir: "~> 1.14",
      description: "a dummy project",
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
      {:project_g, path: "../project_g/"},
      {:foo, "~> 1.0"}
    ]
  end
end
