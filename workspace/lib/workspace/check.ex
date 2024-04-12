defmodule Workspace.Check do
  @check_schema NimbleOptions.new!(
                  module: [
                    type: :atom,
                    required: true,
                    doc: "The `Workspace.Check` module to be used."
                  ],
                  opts: [
                    type: :keyword_list,
                    doc: "The check's custom options.",
                    default: []
                  ],
                  description: [
                    type: :string,
                    doc: "An optional description of the check"
                  ],
                  only: [
                    type: {:list, :atom},
                    doc:
                      "A list of projects. The check will be executed only in the specified projects",
                    default: []
                  ],
                  ignore: [
                    type: {:list, :atom},
                    doc: "A list of projects to be ignored from the check",
                    default: []
                  ],
                  allow_failure: [
                    type: {:or, [:boolean, {:list, :atom}]},
                    doc: """
                    A list of projects (or `true` for all) that are allowed to fail. In case of
                    a failure it will be logged as a warning but the exit code of check will not
                    be set to 1.
                    """,
                    default: false
                  ]
                )

  @moduledoc """
  A behaviour for implementing workspace checker.

  ## Introduction

  A check is responsible for validating that a workspace follows the
  configured rules.

  When your mono-repo grows it is becoming more tedious to keep track with
  all projects and ensure that the same standards apply to all projects. For
  example you may wish to have common dependencies defined across all your
  projects, or common `deps` paths.

  ## Configuration

  In order to define a `Workspace.Check` you must add an entry under the `:checks`
  key of your `Workspace.Config`. The supported options are for each check are:

  #{NimbleOptions.docs(@check_schema)}

  ## Configuration Examples

  ```elixir
  [
    checks: [
      [
        module: Workspace.Checks.ValidateConfigPath,
        description: "check deps_path",
        opts: [
          config_attribute: :deps_path,
          expected_path: "deps"
        ]
      ]
    ]
  ]
  ```

  ## Implementing a `Workspace.Check`

  TODO
  """

  @doc """
  Applies a workspace check on the given workspace
  """
  # TODO: check this callback, maybe we can change it to run on a single project
  # and return {:ok, } {:error} tuples
  # we can add an optional workspace-check for running on the complete workspace
  @callback check(workspace :: Workspace.State.t(), check :: keyword()) :: [
              Workspace.Check.Result.t()
            ]

  @doc """
  Formats a check result for display purposes.
  """
  @callback format_result(result :: Workspace.Check.Result.t()) :: IO.ANSI.ansidata()

  @doc """
  An optional definition of the custom check's options.

  If not set the options will not be validated and all keyword lists will be considered
  valid. It is advised to define it for better handling of errors.
  """
  @callback schema() :: NimbleOptions.t() | nil

  @optional_callbacks [schema: 0]

  # TODO: add a __USING__ macro

  @doc """
  Validates that the given `config` is a valid `Check` config.
  """
  @spec validate(config :: keyword()) ::
          {:ok, keyword()} | {:error, binary()}
  def validate(config) do
    with {:ok, config} <- validate_schema(config),
         {:ok, module} <- ensure_loaded_module(config[:module]),
         {:ok, module} <- validate_check_module(module),
         {:ok, opts_config} <- validate_check_options(module, config[:opts]) do
      {:ok, Keyword.put(config, :opts, opts_config)}
    end
  end

  defp validate_schema(config) do
    case NimbleOptions.validate(config, @check_schema) do
      {:ok, config} -> {:ok, config}
      {:error, %NimbleOptions.ValidationError{message: message}} -> {:error, message}
    end
  end

  defp ensure_loaded_module(module) do
    case Code.ensure_loaded(module) do
      {:module, module} ->
        {:ok, module}

      {:error, error_type} ->
        {:error, "could not load check module #{inspect(module)}: #{inspect(error_type)}"}
    end
  end

  defp validate_check_module(module) do
    behaviours = module.module_info[:attributes][:behaviour] || []

    case Workspace.Check in behaviours do
      true -> {:ok, module}
      false -> {:error, "#{inspect(module)} does not implement the `Workspace.Check` behaviour"}
    end
  end

  defp validate_check_options(module, opts) do
    if function_exported?(module, :schema, 0) do
      case NimbleOptions.validate(opts, module.schema()) do
        {:ok, opts} ->
          {:ok, opts}

        {:error, %NimbleOptions.ValidationError{message: message}} ->
          {:error, "invalid check options: #{message}"}
      end
    else
      {:ok, opts}
    end
  end

  @doc """
  Helper function for running a check on all projects of a workspace.

  The function must return `{:ok, metadata}` or `{:error, metadata}`. It returns
  a `Check.Result` for each checked project.

  It takes care of transforming the function output to a `Check.Result` struct
  and handling ignored projects...
  """
  @spec check_projects(
          workspace :: Workspace.State.t(),
          check :: keyword(),
          check_fun :: (Workspace.Project.t() -> {atom(), keyword()})
        ) :: [Workspace.Check.Result.t()]
  def check_projects(workspace, check, check_fun) do
    for {_app, project} <- workspace.projects do
      case applicable?(check, project) do
        true ->
          {status, metadata} = check_fun.(project)

          status = maybe_demote_status(status, project, check)

          Workspace.Check.Result.new(check, project)
          |> Workspace.Check.Result.set_status(status)
          |> Workspace.Check.Result.set_metadata(metadata)

        false ->
          Workspace.Check.Result.new(check, project)
          |> Workspace.Check.Result.set_status(:skip)
      end
    end
  end

  defp applicable?(check, project) do
    cond do
      # project is set to skip
      project.skip ->
        false

      # If the project is in ignore, ignore it
      project.app in check[:ignore] ->
        false

      # if only is set check if the project is in the only list ->
      check[:only] != [] ->
        project.app in check[:only]

      # in any other case the check is applicable
      true ->
        true
    end
  end

  defp maybe_demote_status(:error, project, check) do
    cond do
      check[:allow_failure] == true ->
        :warn

      is_list(check[:allow_failure]) and project.app in check[:allow_failure] ->
        :warn

      true ->
        :error
    end
  end

  defp maybe_demote_status(status, _project, _check), do: status
end
