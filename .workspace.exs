[
  ignore_paths: [".elixir-tools", "artifacts", "cover"],
  checks: [
    # General package validations
    [
      id: :description_set,
      group: "Package checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have a description set",
      opts: [
        validate: fn project ->
          case project.config[:description] do
            nil -> {:error, "no :description set"}
            description when is_binary(description) -> {:ok, "description set to #{description}"}
            other -> {:error, "description must be binary, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      id: :maintainer_set,
      group: "Package checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have a maintainer set",
      opts: [
        validate: fn project ->
          config = project.config
          package = config[:package] || []

          case package[:maintainers] do
            value when value in [nil, []] -> {:error, ":maintainers must be set under :package"}
            maintainers -> {:ok, "maintainers set to: #{inspect(maintainers)}"}
          end
        end
      ]
    ],
    [
      id: :mit_license,
      group: "Package checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have licenses set to MIT",
      opts: [
        validate: fn project ->
          config = project.config
          package = config[:package] || []

          case package[:licenses] do
            ["MIT"] -> {:ok, "license set to MIT"}
            other -> {:error, "invalid licenses, expected [\"MIT\"], got #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      id: :github_link,
      group: "Package checks",
      module: Workspace.Checks.ValidateProject,
      description: "all packages must have the correct GitHub link",
      opts: [
        validate: fn project ->
          config = project.config
          package = config[:package] || []
          links = package[:links] || %{}

          case links["GitHub"] do
            "https://github.com/sportradar/elixir-workspace" ->
              {:ok, "GitHub link properly set"}

            other ->
              {:error, "invalid GitHub link: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      id: :changelog_link,
      group: "Package checks",
      module: Workspace.Checks.ValidateProject,
      description: "all packages must have the correct Changelog link",
      opts: [
        validate: fn project ->
          config = project.config
          package = config[:package] || []
          links = package[:links] || %{}
          path = Path.relative_to(project.path, project.workspace_path)

          expected_url =
            "https://github.com/sportradar/elixir-workspace/blob/main/#{path}/CHANGELOG.md"

          case links["Changelog"] do
            ^expected_url ->
              {:ok, "Changelog link properly set"}

            other ->
              {:error, "invalid Changelog link: #{inspect(other)}, expected: #{expected_url}"}
          end
        end
      ]
    ],
    # Build paths checks
    [
      id: :deps_path,
      group: "Build paths checks",
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common dependencies path",
      opts: [
        config_attribute: :deps_path,
        expected_path: "artifacts/deps"
      ]
    ],
    [
      id: :build_path,
      group: "Build paths checks",
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common build path",
      opts: [
        config_attribute: :build_path,
        expected_path: "artifacts/build"
      ]
    ],
    # Dependencies checks
    [
      id: :deps_versions,
      group: "Dependencies checks",
      module: Workspace.Checks.DependenciesVersion,
      description: "mono-repo dependencies versions",
      opts: [
        deps: [
          nimble_options: [version: "~> 1.1.1"],
          # dev dependencies
          dialyxir: [
            version: "== 1.4.4",
            options: [only: [:dev], runtime: false]
          ],
          ex_doc: [version: "== 0.34.2"],
          credo: [version: "== 1.7.8"],
          doctor: [version: "== 0.21.0"]
        ]
      ]
    ],
    # Documentation related checks
    [
      id: :docs_output_path,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateConfigPath,
      description: "all projects must have a common docs output path",
      opts: [
        config_attribute: [:docs, :output],
        expected_path: fn project -> "artifacts/docs/#{project.app}" end
      ]
    ],
    [
      id: :html_formatter,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have only html docs formatters",
      opts: [
        validate: fn project ->
          case project.config[:docs][:formatters] do
            ["html"] -> {:ok, "only html present in formatters"}
            other -> {:error, "expected :docs :formatters to be html, got #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      id: :name_set,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have a name set",
      opts: [
        validate: fn project ->
          case project.config[:name] do
            nil -> {:error, "no :name set"}
            name when is_binary(name) -> {:ok, "name set to #{name}"}
            other -> {:error, "description must be binary, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      id: :source_url_pattern,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have a valid source_url_pattern",
      opts: [
        validate: fn project ->
          config = project.config
          url_pattern = get_in(config, [:docs, :source_url_pattern])

          repo_url = "https://github.com/sportradar/elixir-workspace"
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
      id: :source_url,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have the same source_url set",
      opts: [
        validate: fn project ->
          expected_url = "https://github.com/sportradar/elixir-workspace"

          case project.config[:source_url] do
            ^expected_url ->
              {:ok, ":source_url properly set"}

            other ->
              {:error, "expected :source_url to be #{expected_url}, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      id: :canonical_in_docs,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have the :canonical option properly set",
      opts: [
        validate: fn project ->
          config = project.config
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
      id: :common_docs_in_extras,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "common files must be in docs extras",
      opts: [
        validate: fn project ->
          config = project.config
          extras = get_in(config, [:docs, :extras])

          cond do
            is_nil(extras[:"README.md"]) ->
              {:error, "README.md must be present in docs extras"}

            is_nil(extras[:"CHANGELOG.md"]) ->
              {:error, "CHANGELOG.md must be present in docs extras"}

            is_nil(extras[:LICENSE]) ->
              {:error, "LICENSE must be present in docs extras"}

            true ->
              {:ok, "all extra files are present"}
          end
        end
      ]
    ],
    [
      id: :main_docs_entry,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "readme must be the main entry for all docs",
      opts: [
        validate: fn project ->
          case get_in(project.config, [:docs, :main]) do
            "readme" -> {:ok, "readme is the main entry point"}
            other -> {:error, "expected readme as the main page for docs, got: #{inspect(other)}"}
          end
        end
      ]
    ],
    [
      id: :changelog_skip_undefined,
      group: "Documentation checks",
      module: Workspace.Checks.ValidateProject,
      description: "CHANGELOG must be in the skip_undefined_reference_warnings_on list",
      opts: [
        validate: fn project ->
          skipped = get_in(project.config, [:docs, :skip_undefined_reference_warnings_on]) || []

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
      id: :coverage_output,
      group: "Testing checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have test_coverage[:output] properly set",
      opts: [
        validate: fn project ->
          config = project.config
          coverage_opts = config[:test_coverage] || []
          output = coverage_opts[:output]

          cond do
            is_nil(output) ->
              {:error, ":output option not defined under :test_coverage settings"}

            not String.ends_with?(output, Atom.to_string(config[:app])) ->
              {:error, ":output must point to a folder with the same name as the app name"}

            true ->
              {:ok, "coverage output set to #{output}"}
          end
        end
      ]
    ],
    [
      id: :coverage_export,
      group: "Testing checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have test_coverage[:export] properly set",
      opts: [
        validate: fn project ->
          config = project.config
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
      id: :minimum_coverage,
      group: "Testing checks",
      module: Workspace.Checks.ValidateProject,
      description: "all projects must have a minimum coverage threshold of 95",
      opts: [
        validate: fn project ->
          config = project.config
          coverage_opts = config[:test_coverage] || []
          threshold = coverage_opts[:threshold] || 0

          if threshold >= 95 do
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
