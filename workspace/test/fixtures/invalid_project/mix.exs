defmodule InvalidProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :invalid_project,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      workspace: [
        tags: 1
      ]
    ]
  end

  def application do
    []
  end
end
