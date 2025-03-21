defmodule Workspace.Checks.ValidateConfigPath do
  @schema NimbleOptions.new!(
            config_attribute: [
              type: {:or, [:atom, {:list, :atom}]},
              doc: """
              The configuration attribute to check. This can either be a
              single atom or a list of atoms for nested config options.
              """,
              required: true
            ],
            expected_path: [
              type: {:or, [:string, {:fun, 1}]},
              doc: """
              Relative path with respect to the workspace root. This
              can either be a relative path with respect to workspace root or an
              anonymous function taking as input a `Workspace.Project` and returning
              a dynamic expected path.
              """
            ]
          )
  @moduledoc """
  Checks that the given path is properly configured

  > #### Common use case {: .tip}
  >
  > This is useful in cases you want to specify a common path for some of
  > your project's artifacts, e.g. `deps_path` or `build_path`. This will
  > check that the configuration option of the given project matches the
  > expected path. Notice that the expected path is always considered to
  > be relative to the project's workspace path.

  ## Configuration

  #{NimbleOptions.docs(@schema)}

  ## Example

  In order to configure this check add the following, under `checks`,
  in your `.workspace.exs`:

  ```elixir
  [
    module: Workspace.Checks.ValidateConfigPath,
    description: "all projects must have a common dependencies path",
    opts: [
      config_attribute: :deps_path,
      expected_path: "artifacts/deps"
    ]
  ]
  ```
  """
  @behaviour Workspace.Check

  @impl Workspace.Check
  def schema, do: @schema

  @impl Workspace.Check
  def check(workspace, check) do
    config_attribute = Keyword.fetch!(check[:opts], :config_attribute)
    expected_path = Keyword.fetch!(check[:opts], :expected_path)

    Workspace.Check.check_projects(workspace, check, fn project ->
      check_config_path(project, config_attribute, expected_path)
    end)
  end

  defp check_config_path(project, config_attribute, expected_path) when is_atom(config_attribute),
    do: check_config_path(project, [config_attribute], expected_path)

  defp check_config_path(project, config_attribute, expected_path)
       when is_list(config_attribute) do
    expected_path = maybe_evaluate(expected_path, project)
    expected_path = make_absolute(project.workspace_path, expected_path)
    configured_path = make_absolute(project.path, safe_get(project.config, config_attribute))

    if configured_path == expected_path do
      {:ok, check_metadata(expected_path, configured_path)}
    else
      {:error, check_metadata(expected_path, configured_path)}
    end
  end

  defp maybe_evaluate(expected_path, project) when is_function(expected_path),
    do: expected_path.(project)

  defp maybe_evaluate(expected_path, _project) when is_binary(expected_path), do: expected_path

  defp safe_get(nil, _), do: nil
  defp safe_get(value, []), do: value
  defp safe_get(container, _) when not is_list(container), do: nil

  defp safe_get(container, [next_key | keys]) when is_list(container),
    do: safe_get(Keyword.get(container, next_key, nil), keys)

  defp make_absolute(_base_path, nil), do: nil
  defp make_absolute(_base_path, path) when not is_binary(path), do: inspect(path)

  defp make_absolute(base_path, relative) do
    base_path
    |> Path.join(relative)
    |> Path.expand()
  end

  @impl Workspace.Check
  def format_result(%Workspace.Check.Result{
        status: :error,
        meta: meta,
        check: check,
        project: project
      }) do
    attribute = check[:opts][:config_attribute]

    expected = Path.relative_to(meta[:expected], project.path, force: true)

    configured =
      case meta[:configured] do
        nil -> "nil"
        configured -> Path.relative_to(configured, project.path, force: true)
      end

    [
      "expected ",
      :light_cyan,
      inspect(attribute),
      :reset,
      " to be ",
      :light_cyan,
      "#{expected}",
      :reset,
      ", got: ",
      :light_cyan,
      "#{configured}"
    ]
  end

  def format_result(%Workspace.Check.Result{
        check: check,
        meta: meta,
        project: project,
        status: :ok
      }) do
    attribute = check[:opts][:config_attribute]
    expected = Path.relative_to(meta[:expected], project.path, force: true)

    [
      :light_cyan,
      inspect(attribute),
      :reset,
      " is set to ",
      :light_cyan,
      "#{expected}"
    ]
  end

  defp check_metadata(expected, configured) do
    [expected: expected, configured: configured]
  end
end
