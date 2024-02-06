# Checks related helper functions
defmodule Workspace.CheckCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Workspace.CheckCase
      import Workspace.TestUtils
    end
  end

  def check_result(results, %Workspace.Project{app: app}) do
    check_result(results, app)
  end

  def check_result(results, app) when is_atom(app) do
    Enum.find(results, fn result -> result.project.app == app end)
  end

  def assert_check_status(results, project, status) do
    result = check_result(results, project)
    assert result.status == status
  end

  def assert_check_meta(results, project, meta) do
    result = check_result(results, project)
    assert result.meta == meta
  end

  def assert_formatted_result(results, project, expected) do
    result = check_result(results, project)
    assert result.module.format_result(result) == expected
  end
end
