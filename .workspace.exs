[
  ignore_paths: [".elixir-tools", "artifacts", "cover"],
  checks: [
    # General package validations
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
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have a maintainer set",
      opts: [
        validate: fn config ->
          package = config[:package] || []

          case package[:maintainers] do
            value when value in [nil, []] -> {:error, ":maintainers must be set under :package"}
            maintainers -> {:ok, "maintainers set to: #{inspect(maintainers)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "minimum elixir version",
      opts: [
        validate: fn config ->
          case config[:elixir] do
            "~> 1.15" -> {:ok, ""}
            other -> {:error, "expected :elixir to be ~> 1.15, got #{other}"}
          end
        end
      ]
    ],
    # Build paths checks
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
    # Dependencies checks
    [
      module: Workspace.Checks.DependenciesVersion,
      description: "mono-repo dependencies versions",
      opts: [
        deps: [
          # add dependencies in strict alphabetical order
          {:dialyxir, "== 1.4.3", only: [:dev], runtime: false},
          {:ex_doc, "== 0.32.0", no_options_check: true}
        ]
      ]
    ],
    # Documentation related checks
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
      description: "all projects must have a name set",
      opts: [
        validate: fn config ->
          case config[:name] do
            nil -> {:error, "no :name set"}
            name when is_binary(name) -> {:ok, "name set to #{name}"}
            other -> {:error, "description must be binary, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have a valid source_url_pattern",
      opts: [
        validate: fn config ->
          url_pattern = get_in(config, [:docs, :source_url_pattern])

          repo_url = "https://github.com/pnezis/workspace"
          app = Keyword.fetch!(config, :app)
          version = Keyword.fetch!(config, :version)

          expected_url = "#{repo_url}/blob/#{app}/v#{version}/#{app}/%{path}#L%{line}"

          if url_pattern == expected_url do
            {:ok, ":source_url_pattern correctly set to #{url_pattern}"}
          else
            {:error,
             "invalid :source_url_pattern, expected #{expected_url}, got: #{inspect(url_pattern)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have the same source_url set",
      opts: [
        validate: fn config ->
          expected_url = "https://github.com/pnezis/workspace"

          case config[:source_url] do
            ^expected_url ->
              {:ok, ":source_url properly set"}

            other ->
              {:error, "expected :source_url to be #{expected_url}, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have the :canonical option properly set",
      opts: [
        validate: fn config ->
          canonical = get_in(config, [:docs, :canonical])
          expected = "http://hexdocs.pm/#{config[:app]}"

          if canonical == expected do
            {:ok, ":canonical properly set to #{canonical}"}
          else
            {:error,
             "invalid :canonical value, expected: #{expected}, got: #{inspect(canonical)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "common files must be in docs extras",
      opts: [
        validate: fn config ->
          extras = get_in(config, [:docs, :extras])

          cond do
            is_nil(extras[:"README.md"]) ->
              {:error, "README.md must be present in docs extras"}

            is_nil(extras[:"CHANGELOG.md"]) ->
              {:error, "CHANGELOG.md must be present in docs extras"}

            true ->
              {:ok, "all extra files are present"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "readme must be the main entry for all docs",
      opts: [
        validate: fn config ->
          case get_in(config, [:docs, :main]) do
            "readme" -> {:ok, "readme is the main entry point"}
            other -> {:error, "expected readme as the main page for docs, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "CHANGELOG must be in the skip_undefined_reference_warnings_on list",
      opts: [
        validate: fn config ->
          skipped = get_in(config, [:docs, :skip_undefined_reference_warnings_on]) || []

          case "CHANGELOG.md" in skipped do
            true ->
              {:ok, "CHANGELOG included in :skip_undefined_reference_warnings_on"}

            false ->
              {:error,
               "CHANGELOG.md should be included under :skip_undefined_reference_warnings_on"}
          end
        end
      ]
    ],
    # Testing related checks
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have test_coverage[:output] properly set",
      opts: [
        validate: fn config ->
          coverage_opts = config[:test_coverage] || []
          output = coverage_opts[:output]

          cond do
            is_nil(output) ->
              {:error, ":output option not defined under :test_coverage settings"}

            not String.ends_with?(output, Atom.to_string(config[:app])) ->
              {:error, ":output must point to a folder with the same name as the app name"}

            true ->
              {:ok, ""}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have test_coverage[:export] properly set",
      opts: [
        validate: fn config ->
          coverage_opts = config[:test_coverage] || []
          export = coverage_opts[:export]

          cond do
            export == nil ->
              {:error, "export option not defined under :test_coverage settings"}

            is_binary(export) and String.starts_with?(export, Atom.to_string(config[:app])) ->
              {:ok, "output properly set to #{export}"}

            true ->
              {:error,
               "invalid value for output, it should be a binary starting with #{config[:app]}, got: #{inspect(export)}"}
          end
        end
      ]
    ],
    [
      module: Workspace.Checks.ValidateConfig,
      description: "all projects must have a minimum coverage threshold of 98",
      opts: [
        validate: fn config ->
          coverage_opts = config[:test_coverage] || []
          threshold = coverage_opts[:threshold] || 0

          if threshold >= 98 do
            {:ok, "threshold is at #{threshold}%"}
          else
            {:error, "threshold must be at least 98, got: #{threshold}"}
          end
        end
      ]
    ]
  ],
  test_coverage: [
    allow_failure: [:workspace],
    threshold: 98,
    warning_threshold: 99,
    exporters: [
      lcov: fn workspace, coverage_stats ->
        Workspace.Coverage.LCOV.export(workspace, coverage_stats,
          output_path: "artifacts/coverage"
        )
      end
    ]
  ]
]
