[
  ignore_paths: [".elixir-tools", "artifacts", "cover"],
  checks: [
    [
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common dependencies path",
      opts: [
        config_attribute: :deps_path,
        expected_path: "artifacts/deps"
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common build path",
      opts: [
        config_attribute: :build_path,
        expected_path: "artifacts/build"
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common docs output path",
      opts: [
        config_attribute: [:docs, :output],
        expected_path: fn project -> "artifacts/docs/#{project.app}" end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have only html docs formatters",
      opts: [
        validate: fn config ->
          case config[:docs][:formatters] do
            ["html"] -> {:ok, ""}
            other -> {:error, "expected :docs :formatters to be html, got #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have elixir set to 1.13",
      opts: [
        validate: fn config ->
          case config[:elixir] do
            "~> 1.13" -> {:ok, ""}
            other -> {:error, "expected :elixir to be ~> 1.13, got #{other}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have a description set",
      opts: [
        validate: fn config ->
          case config[:description] do
            nil -> {:error, "no :description set"}
            description when is_binary(description) -> {:ok, ""}
            other -> {:error, "description must be binary, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common coverage output path",
      opts: [
        config_attribute: [:test_coverage, :output],
        expected_path: "artifacts/coverdata"
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have test coverage export option set",
      opts: [
        validate: fn config ->
          coverage_opts = config[:test_coverage] || []

          case coverage_opts[:export] do
            nil -> {:error, "export option not defined under :test_coverage settings"}
            _value -> {:ok, ""}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.DependenciesVersion,
      description: "mono-repo dependencies versions",
      opts: [
        deps: [
          # add dependencies in strict alphabetical order
          {:dialyxir, "== 1.4.3", only: [:dev], runtime: false},
          {:ex_doc, "== 0.31.2", no_options_check: true},
          {:timex, "== 3.7.7"}
        ]
      ]
    ]
  ],
  test_coverage: [
    allow_failure: [:workspace],
    threshold: 40,
    exporters: [
      lcov: fn workspace, coverage_stats ->
        Workspace.Coverage.LCOV.export(workspace, coverage_stats,
          output_path: "artifacts/coverage"
        )
      end
    ]
  ]
]
