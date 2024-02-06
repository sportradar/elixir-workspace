defmodule TestCoverageWorkspace.MixWorkspace do
  use Mix.Project

  def project do
    [
      app: :test_coverage_workspace,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: [],
      workspace: [
        type: :workspace
      ]
    ]
  end
end
