defmodule Workspace.Checks.RequiredScopeTag do
  @schema NimbleOptions.new!(
            scope: [
              type: :atom,
              required: true,
              doc: "The required scope."
            ],
            multiple: [
              type: :boolean,
              default: false,
              doc: """
              If set to `true` the same scope is allowed to be defined multiple
              times. If set to `false` (the default) the check will fail if the
              project has more than one tags with the given scope.
              """
            ]
          )

  @moduledoc """
  Checks that the project has at least one scope tag with the given scope.

  This check can be used in order to validate that all (or some) of the workspace
  projects have at least one tag with the given scope defined. By default it is
  allowed to set only one tag for a scope, but you can override this by setting
  the `:multiple` option to `true`.

  > #### Common use cases {: .tip}
  >
  > A common use case for this check is when you want to use scoped tags for
  > enforcing boundaries or defining the architectural level of each package.
  > In these cases it is a good practice to require all packages to have
  > some specific scope allowed.

  ## Configuration

  #{NimbleOptions.docs(@schema)}

  ## Example

  In order to configure this check add the following, under `checks`, in your workspace
  config:

  ```elixir
  [
    module: Workspace.Checks.RequiredScopeTag,
    description: "all projects must have a {:type, _value} tag set",
    opts: [
      scope: :type   
    ]
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @impl Workspace.Check
  def check(workspace, check) do
    scope = Keyword.fetch!(check[:opts], :scope)
    multiple = Keyword.fetch!(check[:opts], :multiple)

    Workspace.Check.check_projects(workspace, check, fn project ->
      validate_required_scope_tag(project, scope, multiple)
    end)
  end

  defp validate_required_scope_tag(project, scope, multiple) do
    scope_tags = Workspace.Project.scoped_tags(project, scope)

    cond do
      scope_tags == [] ->
        {:error, [reason: :missing, scope: scope]}

      not multiple and length(scope_tags) > 1 ->
        {:error, [reason: :multiple, scope: scope, tags: scope_tags]}

      true ->
        {:ok, [tags: scope_tags, scope: scope]}
    end
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta
      }) do
    error_reason(meta[:reason], meta[:scope], meta[:tags])
  end

  def format_result(%Workspace.Check.Result{status: :ok, meta: meta}) do
    [
      "defined tags with ",
      :light_cyan,
      inspect(meta[:scope]),
      :reset,
      "scope: ",
      :light_green,
      inspect(meta[:tags]),
      :reset
    ]
  end

  defp error_reason(:missing, scope, _tags),
    do: ["missing tag with scope: ", :light_red, inspect(scope), :reset]

  defp error_reason(:multiple, scope, tags),
    do: [
      "multiple tags with scope ",
      :light_cyan,
      inspect(scope),
      :reset,
      " defined: ",
      :light_red,
      inspect(tags),
      :reset
    ]
end
