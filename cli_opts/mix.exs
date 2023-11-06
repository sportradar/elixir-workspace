defmodule CliOpts.MixProject do
  use Mix.Project

  def project do
    [
      app: :cli_opts,
      description: "parse and validate cli options",
      version: "0.1.0",
      elixir: "~> 1.13",
      # build_path: "../_build",
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [
        export: "cli_opts",
        output: "../artifacts/coverdata"
      ],
      docs: [
        output: "../artifacts/docs/cli_opts",
        formatters: ["html"]
      ]
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
      {:ex_doc, "== 0.30.9", only: :dev, runtime: false},
      {:credo, "~> 1.6.7", [only: [:dev, :test], runtime: false]},
      {:dialyxir, "== 1.4.2", only: [:dev], runtime: false},
      {:doctor, "~> 0.21.0", [only: :dev, runtime: false]}
    ]
  end
end
