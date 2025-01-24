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

  def assert_plain_result(results, project, expected) when is_binary(expected),
    do: assert_plain_result(results, project, [expected])

  def assert_plain_result(results, project, expected) do
    result = check_result(results, project)

    plain_result =
      result.module.format_result(result)
      |> Enum.reject(&is_atom/1)
      |> IO.ANSI.format(false)
      |> :erlang.iolist_to_binary()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)

    expected = Enum.map(expected, &String.trim/1)

    assert plain_result == expected
  end
end
