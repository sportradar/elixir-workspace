defmodule Workspace.Checks.ValidateConfig do
  @schema NimbleOptions.new!(
            validate: [
              type: {:fun, 1},
              required: true,
              doc: """
              An anonymous function of arity 1 for validating a project's config. The project's
              config is passed as input to the user provided function. It must return one of:

              - `{:ok, message :: String.t()}` in case of success
              - `{:error, message :: String.t()}` in case of error
              """
            ]
          )

  @moduledoc """
  Checks that the given config is valid

  This is a generic check since you can define any arbitrary check for
  the given config.

  ## Configuration

  #{NimbleOptions.docs(@schema)}

  ## Example

  In order to configure this checker add the following, under `checks`,
  in your `workspace.exs`:

  ```elixir
  [
    module: Workspace.Checks.ValidateConfig,
    description: "all projects must have elixir version set to 1.13",
    opts: [
      validate: fn config ->
        case config[:elixir] do
          "~> 1.13" -> {:ok, "elixir version set to 1.13"}
          other -> {:error, "wrong elixir version, expected 1.13, got \#\{other\}"}
        end
      end
    ]
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @impl Workspace.Check
  def check(workspace, check) do
    validate_fun = Keyword.fetch!(check[:opts], :validate)

    Workspace.Check.check_projects(workspace, check, fn project ->
      case validate_fun.(project.config) do
        {status, message} when status in [:ok, :error, :skip] and is_binary(message) ->
          {status, [message: message]}

        {status, message} when is_binary(message) ->
          raise ArgumentError,
                "validate function must return a {status, message} tuple where " <>
                  "status one of [:ok, :error, :skip], got: #{status}"

        {_status, message} ->
          raise ArgumentError,
                "validate function must return a {status, message} tuple where " <>
                  "message must be a string, got: #{inspect(message)}"

        other ->
          raise ArgumentError,
                "validate function must return a {status, message} tuple, got #{inspect(other)}"
      end
    end)
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        meta: meta
      }),
      do: meta[:message]
end
