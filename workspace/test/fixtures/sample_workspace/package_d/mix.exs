defmodule PackageD.MixProject do
  use Mix.Project

  def project do
    [
      app: :package_d,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: [],
      docs: &docs/0
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [foo: 1]
  end
end
