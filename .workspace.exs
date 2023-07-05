[
  ignore_paths: ["artifacts/deps"],
  checks: [
    [
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common dependencies path",
      ignore: [:cli_opts],
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
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have elixir set to 1.14",
      allow_failure: [:cli_opts],
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
  ],
  test_coverage: [
    threshold: 40,
    exporters: [
      lcov: fn coverage_stats -> 
        Workspace.Coverage.export_lcov(coverage_stats, [output_path: "artifacts/coverage"])
      end
    ]
  ]
]
