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
      {status, metadata} = check_fun.(project)

      result =
        Workspace.Check.Result.new(check, project)
        |> Workspace.Check.Result.set_status(status)
        |> Workspace.Check.Result.set_metadata(metadata)
        |> Workspace.Check.Result.set_index(check[:index])

      [result | acc]
    end)
  end
end
