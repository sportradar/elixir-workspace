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

  ## The `Workspace.Check` behaviour

  In order to implement and use a custom check you need to:

    1. Define a module implementing the `Workspace.Check` behaviour.
    2. Include your check in the workspace configuration.

  ### The schema

  Let's implement a simple check that verifies that all workspace projects
  have a description set.

  ```elixir
  defmodule MyCheck do
    @behaviour Workspace.Check

    # ...callbacks implementation...
  end
  ```

  We will start by defining the check's schema. This is expected to be a
  `NimbleOptions` schema with the custom options of your check. For the needs
  of this guide we will assume that we support a single option:

  ```elixir
  @impl Workspace.Check
  def schema do
    schema = [
      must_end_with_period: [
        type: :boolean,
        doc: "If set the description must end with a period",
        default: false
      ]
    ]

    NimbleOptions.new!(schema)
  end
  ```

  > #### Schema as module attribute {: .tip}
  >
  > Instead of defining the schema directly in the `c:schema/0` callback it
  > is advised to define it as a module attribute. This way you can auto-generate
  > documentation in your check's `moduledoc`:
  >
  > ```elixir
  > defmodule MyCheck do
  >   @behaviour Workspace.Check
  >
  >   @schema NimbleOptions.new!(
  >     must_end_with_period: [
  >       type: :boolean,
  >       doc: "If set the description must end with a period",
  >       default: false
  >     ] 
  >   )
  >
  >   @moduledoc \"""
  >   My check's documentation
  >
  >   ## Options
  >
  >   \#{NimbleOptions.docs(@schema)}
  >   \"""
  > 
  >   @impl Workspace.Check
  >   def schema, do: @schema
  > end
  > ```

  ### The check

  We can now implement the `c:check/2` callback which is responsbible for the
  actual check logic. In our simple example we only need to verify that the
  `:description` is set in each project's config.

  The `c:check/2` callback is expected to return a list of check results. You
  can use the `check_projects/3` helper method.

  ```elixir
  @impl Workspace.Check
  def check(workspace, check) do
    must_end_with_period = Keyword.fetch!(check[:opts], :must_end_with_period)

    Workspace.Check.check_projects(workspace, check, fn project ->
      description = project.config[:description]

      cond do
        not is_binary(description) ->
          {:error, description: description, message: "description must be a string"}

        must_end_with_period and not String.ends_with?(description, ".") ->
          {:error, description: description, message: "description must end with a period"}

        true ->
          {:ok, description: description}
      end
    end)
  end
  ```

  Notice that the `check_projects/3` helper expects the inner function to return
  `:ok`, `:error` tuples where the second element is check metadata. These metadata are
  used by the `c:format_result/1` callback for pretty printing the check status
  message per project.

  ```elixir
  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{status: :ok, meta: metadata}) do
    "description set to \#{metadata[:description]}"
  end

  def format_result(%Workspace.Check.Result{status: :error, meta: metadata}) do
    message = metadata[:message]
    description = metadata[:description]

    [message, ", got: ", :red, inspect(description), :reset]
  end
  ```

  Notice how we use `IO.ANSI` escape sequences for pretty printing the invalid
  project description.

  For more examples you can check the implementation of the checks provided by
  the workspace.
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
  and handling ignored projects.
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
