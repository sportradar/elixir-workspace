defmodule <%= mod %>.MixWorkspace do
    use Mix.Project

    def project do
      [
        app: :<%= app %>,
        version: "0.1.0",
        elixir: "~> <%= version %>",
        start_permanent: Mix.env() == :prod,
        deps: deps(),
        elixirc_paths: [],
        workspace: [
          type: :workspace
        ],
        lockfile: "workspace.lock"
      ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
      [
        extra_applications: []
      ]
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
      [
        {:workspace, "~> 0.2.0"}
      ]
    end
  end
