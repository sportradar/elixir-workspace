defmodule PackageH.MixProject do
  use Mix.Project

  def project do
    [
      app: :package_h,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: "../deps"
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
      {:package_d, path: "../package_d/"}
    ]
  end
end
