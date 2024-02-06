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
        # TODO: set proper versions once released
        {:workspace, github: "pnezis/workspace", sparse: "workspace"},
        {:cli_opts, github: "pnezis/workspace", sparse: "cli_opts", override: true}
      ]
    end
  end
