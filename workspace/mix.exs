defmodule Workspace.MixProject do
  use Mix.Project

  def project do
    [
      app: :workspace,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      dialyzer: [plt_add_apps: [:mix]]
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
      {:cli_opts, path: "../cli_opts/"},
      {:ex_doc, "~> 0.28", [only: :dev, runtime: false]},
      {:credo, "~> 1.6.7", [only: [:dev, :test], runtime: false]},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", [only: :dev, runtime: false]}
    ]
  end
end
