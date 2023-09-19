defmodule WorkspaceNew.MixProject do
  use Mix.Project

  def project do
    [
      app: :workspace_new,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:eex]
    ]
  end
end
