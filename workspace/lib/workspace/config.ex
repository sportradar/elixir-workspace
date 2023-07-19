defmodule Workspace.Config do
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
                      default: []
                    ]
                  )

  @moduledoc """
  A struct holding workspace configuration.

  ## Options

  The following configuration options are supported:

  #{NimbleOptions.docs(@options_schema)}
  """

  @doc """
  Validates that the given `config` is a valid `Workspace` config.

  A `config` is valid if:

  - it follows the workspace config schema
  - every check is valid, for more details check `Workspace.Check.validate/1`

  Returns either `{:ok, config}` with the updated `config` is it is valid, or
  `{:error, message}` in case of errors.
  """
  @spec validate(config :: keyword()) :: {:ok, keyword()} | {:error, binary()}
  def validate(config) do
    with {:ok, config} <- validate_config(config),
         {:ok, config} <- validate_checks(config) do
      {:ok, config}
    end
  end

  defp validate_config(config) when is_list(config) do
    case NimbleOptions.validate(config, @options_schema) do
      {:ok, config} -> {:ok, config}
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
    end
  end

  defp validate_config(config) do
    {:error, "expected workspace config to be a keyword list, got: #{inspect(config)}"}
  end

  defp validate_checks(config) do
    checks = config[:checks]

    case validate_checks(checks, [], []) do
      {:ok, checks} -> {:ok, Keyword.put(config, :checks, checks)}
      {:error, message} -> {:error, message}
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

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        validate_checks(rest, acc, [message | errors])
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
