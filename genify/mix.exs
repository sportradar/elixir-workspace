defmodule Genify.MixProject do
  use Mix.Project

  def project do
    [
      app: :genify,
      version: "0.1.0",
      elixir: "~> 1.13",
      description: "generate code from templates",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../artifacts/deps",
      build_path: "../artifacts/build",
      docs: [
        output: "../artifacts/docs/genify",
        formatters: ["html"]
      ],
      test_coverage: [
        export: "genify",
        output: "../artifacts/coverdata"
      ],
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cli_opts, path: "../cli_opts/"},
      {:ex_doc, "== 0.30.9", only: :dev, runtime: false},
    ]
  end
end
