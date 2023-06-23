defmodule Workspace.Checks.ValidateConfig do
  @moduledoc """
  Checks that the given config is valid

  This is a generic check since you can define any arbitrary check for
  the given config.

  ## Configuration

  It expects the following configuration parameters:

  * `:validate` - an anonymous function that expects as input the config
  object of the project and returns either `{:ok, message}` or `{:error, message}`.

  In order to configure this checker add the following, under `checks`,
  in your `workspace.exs`:

  ```elixir
  [
    module: Workspace.Checks.ValidateConfig,
    description: "all projects must have elixir version set to 1.13"
    validate: fn config ->
      case config[:elixir] do
        "~> 1.13" -> {:ok, "elixir version set to 1.13"}
        other -> {:error, "wrong elixir version, expected 1.13, got \#\{other\}"}
      end
    end
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def check(workspace, check) do
    validate_fun = Keyword.fetch!(check[:opts], :validate)

    Workspace.Check.check_projects(workspace, check, fn project ->
      {status, message} = validate_fun.(project.config)
      {status, [message: message]}
    end)
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: status,
        meta: meta
      }) do
    case status do
      :skip -> []
      _other -> [meta[:message]]
    end
  end
end
