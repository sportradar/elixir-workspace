defmodule Workspace.Config do
  @test_coverage_schema [
    threshold: [
      type: :non_neg_integer,
      doc: """
      The overall coverage threshold for the workspace. If the overall test coverage is below this
      value then the `workspace.test.coverage` command is considered failed. Notice
      that the overall test coverage percentage is calculated only on the enabled projects.
      """,
      default: 90
    ],
    warning_threshold: [
      type: :non_neg_integer,
      doc: """
      If set it specifies an overall warning threshold under which a warning will be
      raised. If not set it is implied to be the mid value between `threshold` and `100`.
      """
    ],
    exporters: [
      type: :keyword_list,
      doc: """
      Definition of exporters to be used. Each defined exporter must be an anonymous
      function taking as input the `workspace` and the `coverage_stats`. For more
      details check the `Mix.Tasks.Workspace.Test.Coverage` task.
      """
    ],
    allow_failure: [
      type: {:list, :atom},
      doc: """
      A list of projects for which the test coverage is allowed to fail without affecting
      the overall status.
      """,
      default: []
    ]
  ]

  @options_schema NimbleOptions.new!(
                    ignore_projects: [
                      type: {:list, :atom},
                      doc: """
                      A list of project modules to be ignored. If set these projects will
                      not be considered workspace projects when initializing a `Workspace`
                      with the current config.
                      """,
                      default: []
                    ],
                    ignore_paths: [
                      type: {:list, :string},
                      doc: """
                      List of paths relative to the workspace root to be ignored from
                      parsing for projects detection.
                      """,
                      default: []
                    ],
                    checks: [
                      type: {:list, :keyword_list},
                      doc: """
                      List of checks configured for the workspace. For more details check
                      `Workspace.Check`
                      """,
                      default: []
                    ],
                    test_coverage: [
                      type: :keyword_list,
                      doc: """
                      Test coverage configuration for the workspace. Notice that this is
                      independent of the `test_coverage` configuration per project. It is
                      applied in the aggregate coverage and except thresholds you can
                      also configure coverage exporters.
                      """,
                      keys: @test_coverage_schema,
                      default: []
                    ]
                  )

  @moduledoc """
  The workspace configuration.

  The workspace configuration is specified usually in a `.workspace.exs` file in the
  root of your workspace. This is the place to:

    * Configure your workspace checks (`Workspace.Check`)
    * Specify paths or projects to be ignored during the workspace graph generation
    * Define overall workspace coverage thresholds
    * Define any other configuration option may be needed by a third party plugin.

  It is expected to be a keyword list with an arbitrary set of configuration options.

  ## Options

  The following configuration options are supported by default:

  #{NimbleOptions.docs(@options_schema)}

  A simple example of a `.workspace.exs` follows:

  ```elixir
  [
    ignore_paths: ["deps", "artifacts", "cover"],
    checks: [
      # Add your checks here
      [
        module: Workspace.Checks.ValidateProject,
        description: "all projects must have a description set",
        opts: [
          validate: fn project ->
            case project.config[:description] do
              nil -> {:error, "no :description set"}
              description when is_binary(description) -> {:ok, ""}
              other -> {:error, "description must be binary, got: \#{inspect(other)}"}
            end
          end
        ]
      ]
    ],
    test_coverage: [
      allow_failure: [:foo],
      threshold: 98,
      warning_threshold: 99,
      exporters: [
        lcov: fn workspace, coverage_stats ->
          Workspace.Coverage.LCOV.export(workspace, coverage_stats,
            output_path: "artifacts/coverage"
          )
        end
      ]
    ],
    my_awesome_plugin_options: [
      x: 1,
      y: 2
    ]
  ]
  ```


  > #### Extra Options {: .info}
  >
  > Notice that the validation will **not fail** if any extra configuration option
  > is present. This way various plugins or mix tasks may define their own options
  > that can be read from this configuration.
  """

  @doc """
  Loads the workspace config from the given path.

  An error tuple will be returned if the config is invalid.
  """
  @spec load(config_file :: String.t()) :: {:ok, keyword()} | {:error, binary()}
  def load(config_file) do
    config_file = Path.expand(config_file)

    with {:ok, config_file} <- Workspace.Helpers.ensure_file_exists(config_file),
         {config, _bindings} <- Code.eval_file(config_file) do
      {:ok, config}
    end
  end

  @doc """
  Validates that the given `config` is a valid `Workspace` config.

  A `config` is valid if:

  - it follows the workspace config schema
  - every check configuration is valid according to it's own schema. For more details
  check `Workspace.Check.validate/1`.

  Returns either `{:ok, config}` with the updated `config` is it is valid, or
  `{:error, message}` in case of errors.

  Notice that only the default options are validated, since the config may be used by
  plugins for setting custom options.
  """
  @spec validate(config :: keyword()) :: {:ok, keyword()} | {:error, binary()}
  def validate(config) do
    with {:ok, config} <- validate_config(config) do
      validate_checks(config)
    end
  end

  defp validate_config(config) when is_list(config) do
    default_options_config = Keyword.take(config, Keyword.keys(@options_schema.schema))

    # we only validate default options since extra options may be added by
    # plugins
    case NimbleOptions.validate(default_options_config, @options_schema) do
      {:ok, default_options_config} -> {:ok, Keyword.merge(config, default_options_config)}
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
    end
  end

  defp validate_config(config) do
    {:error, "expected workspace config to be a keyword list, got: #{inspect(config)}"}
  end

  defp validate_checks(config) do
    checks = config[:checks]

    with {:ok, checks} <- validate_checks(checks, [], []),
         :ok <- ensure_unique_check_ids(checks) do
      {:ok, Keyword.put(config, :checks, checks)}
    end
  end

  defp validate_checks([], checks, []), do: {:ok, :lists.reverse(checks)}

  defp validate_checks([], _checks, errors) do
    errors = :lists.reverse(errors) |> Enum.join("\n")
    {:error, "failed to validate checks:\n #{errors}"}
  end

  defp validate_checks([check | rest], acc, errors) do
    case Workspace.Check.validate(check) do
      {:ok, check} ->
        validate_checks(rest, [check | acc], errors)

      {:error, message} ->
        validate_checks(rest, acc, [message | errors])
    end
  end

  defp ensure_unique_check_ids(checks) do
    # TODO: remove filter once id required
    duplicates =
      checks
      |> Enum.map(fn check -> check[:id] end)
      |> Enum.reject(&is_nil/1)
      |> Enum.group_by(& &1)
      |> Enum.filter(&match?({_id, [_, _ | _]}, &1))

    case duplicates do
      [] ->
        :ok

      duplicates ->
        {:error,
         "check ids must be unique, the following have duplicates: #{inspect(Keyword.keys(duplicates))}"}
    end
  end

  @doc """
  Same as `validate/1` but raises an `ArgumentError` exception in case of failure.

  In case of success the validated configuration keyword list is returned.
  """
  @spec validate!(config :: keyword()) :: keyword()
  def validate!(config) do
    case validate(config) do
      {:ok, config} -> config
      {:error, message} -> raise ArgumentError, message: message
    end
  end
end
