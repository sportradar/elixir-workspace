defmodule Workspace.CheckTest do
  use CheckTest.Case

  setup do
    project_a = project_fixture(app: :foo)
    project_b = project_fixture(app: :bar)

    workspace = workspace_fixture([project_a, project_b])

    %{workspace: workspace}
  end

  describe "properly handles statuses" do
    test "returns the actual status if no allow_failure is set", %{workspace: workspace} do
      check =
        check_fixture(fn config ->
          case config[:app] do
            :foo -> {:ok, ""}
            :bar -> {:error, "an error"}
          end
        end)

      results = check[:module].check(workspace, check)

      assert_check_status(results, :foo, :ok)
      assert_check_status(results, :bar, :error)
    end

    test "demotes all statuses if allow_failure is set to true", %{workspace: workspace} do
      check = check_fixture(fn _config -> {:error, "an error"} end, allow_failure: true)

      results = check[:module].check(workspace, check)

      assert_check_status(results, :foo, :warn)
      assert_check_status(results, :bar, :warn)
    end

    test "demotes status if allow_failure is set for specific project", %{workspace: workspace} do
      check = check_fixture(fn _config -> {:error, "an error"} end, allow_failure: [:bar])

      results = check[:module].check(workspace, check)

      assert_check_status(results, :foo, :error)
      assert_check_status(results, :bar, :warn)
    end

    test "raises if invalid status", %{workspace: workspace} do
      check = check_fixture(fn _config -> {:invalid, "an error"} end, allow_failure: true)

      message = """
      validate function must return a {status, message} tuple where status \
      one of [:ok, :error, :skip], got: invalid\
      """

      assert_raise ArgumentError, message, fn -> check[:module].check(workspace, check) end
    end
  end

  defp check_fixture(fun, opts \\ []) do
    check_config =
      Keyword.merge(
        [
          module: Workspace.Checks.ValidateConfig,
          opts: [
            validate: fn config -> fun.(config) end
          ]
        ],
        opts
      )

    {:ok, check} = Workspace.Check.validate(check_config)

    check
  end
end
