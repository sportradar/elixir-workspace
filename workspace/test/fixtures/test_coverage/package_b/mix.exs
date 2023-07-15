defmodule PackageB.MixProject do
  use Mix.Project

  def project do
    [
      app: :package_b,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_pattern: "*_test_fixture.exs",
      test_coverage: [
        export: "package_b"
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
      {:package_c, path: "../package_c/"}
    ]
  end
end
