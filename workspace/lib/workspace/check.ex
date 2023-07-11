defmodule Workspace.Check do
  @schema [
    module: [
      type: :atom,
      required: true,
      doc: "The `Workspace.Check` module to be used."
    ],
    opts: [
      type: :keyword_list,
      doc: "The check's custom options."
    ],
    description: [
      type: :string,
      doc: "An optional description of the check"
    ],
    only: [
      type: {:list, :atom},
      doc: "A list of projects. The check will be executed only in the specified projects",
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
  ]

  @moduledoc """
  A behaviour for implementing workspace checker.

  ## Introduction

  A checker is responsible for validating that a workspace follows the
  configured rules.

  When your mono-repo grows it is becoming more tedious to keep track with
  all projects and ensure that the same standards apply to all projects. For
  example you may wish to have common dependencies defined across all your
  projects, or common `deps` paths.

  ## Configuration

  In order to define a `Check` you must add an entry under the `:check` key
  of your workspace config. The supported options are:

  #{NimbleOptions.docs(@schema)}

  For example:

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
  """

  @doc """
  Applies a workspace check on the given workspace
  """
  @callback check(workspace :: Workspace.t(), check :: keyword()) :: [
              Workspace.Check.Result.t()
            ]

  @doc """
  Formats a check result for display purposes.
  """
  @callback format_result(result :: Workspace.Check.Result.t()) :: IO.ANSI.ansidata()

  # TODO: add a schema callback
  # TODO: add a __using__ macro and document it properly

  @doc """
  Validates that the given `config` is a valid `Check` config.
  """
  @spec validate(config :: keyword()) ::
          {:ok, keyword()} | {:error, NimbleOptions.ValidationError.t()}
  def validate(config) do
    NimbleOptions.validate(config, @schema)
  end

  @doc """
  Helper function for running a check on all projects of a workspace.

  The function must return `{:ok, metadata}` or `{:error, metadata}`. It returns
  a `Check.Result` for each checked preject.

  It takes care of transforming the function output to a `Check.Result` struct
  and handling ignored projects...
  """
  @spec check_projects(
          workspace :: Workspace.t(),
          check :: keyword(),
          check_fun :: (Workspace.Project.t() -> {atom(), keyword()})
        ) :: [Workspace.Check.Result.t()]
  def check_projects(workspace, check, check_fun) do
    Enum.reduce(workspace.projects, [], fn project, acc ->
      result =
        case applicable?(check, project) do
          true ->
            {status, metadata} = check_fun.(project)

            status = maybe_demote_status(status, project, check)

            Workspace.Check.Result.new(check, project)
            |> Workspace.Check.Result.set_status(status)
            |> Workspace.Check.Result.set_metadata(metadata)
            |> Workspace.Check.Result.set_index(check[:index])

          false ->
            Workspace.Check.Result.new(check, project)
            |> Workspace.Check.Result.set_status(:skip)
            |> Workspace.Check.Result.set_index(check[:index])
        end

      [result | acc]
    end)
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
