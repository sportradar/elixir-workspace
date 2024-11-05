defmodule Workspace.CheckTest do
  use Workspace.CheckCase

  setup do
    project_a = project_fixture(app: :foo)
    project_b = project_fixture(app: :bar)

    workspace = workspace_fixture([project_a, project_b])

    %{workspace: workspace}
  end

  defmodule CheckModule do
    @behaviour Workspace.Check

    @impl true
    def check(_workspace, _check), do: []

    @impl true
    def format_result(_result), do: []

    @impl true
    def schema, do: [foo: [type: :string, required: true], bar: [type: :integer, default: 1]]
  end

  describe "validate/1" do
    test "with a valid config" do
      assert {:ok, config} =
               Workspace.Check.validate(id: :test_check, module: CheckModule, opts: [foo: "bar"])

      # check that the config is updated
      assert config[:allow_failure] == false
      assert config[:opts] == [bar: 1, foo: "bar"]
    end

    test "fails if the module is invalid" do
      assert {:error, message} = Workspace.Check.validate(module: InvalidCheckModule)
      assert message =~ "could not load check module InvalidCheckModule: :nofile"
    end

    test "fails if the module is not a Workspace.Check" do
      assert {:error, message} = Workspace.Check.validate(module: Enum)
      assert message =~ "Enum does not implement the `Workspace.Check` behaviour"
    end

    test "fails if the custom options are invalid" do
      assert {:error, message} = Workspace.Check.validate(module: CheckModule)

      assert message =~
               "invalid check options: required :foo option not found, received options: []"
    end
  end

  describe "properly handles statuses" do
    test "returns the actual status if no allow_failure is set", %{workspace: workspace} do
      check =
        check_fixture(fn project ->
          case project.config[:app] do
            :foo -> {:ok, ""}
            :bar -> {:error, "an error"}
          end
        end)

      results = check[:module].check(workspace, check)

      assert_check_status(results, :foo, :ok)
      assert_check_status(results, :bar, :error)
    end

    test "demotes all statuses if allow_failure is set to true", %{workspace: workspace} do
      check = check_fixture(fn _project -> {:error, "an error"} end, allow_failure: true)

      results = check[:module].check(workspace, check)

      assert_check_status(results, :foo, :warn)
      assert_check_status(results, :bar, :warn)
    end

    test "demotes status if allow_failure is set for specific project", %{workspace: workspace} do
      check = check_fixture(fn _project -> {:error, "an error"} end, allow_failure: [:bar])

      results = check[:module].check(workspace, check)

      assert_check_status(results, :foo, :error)
      assert_check_status(results, :bar, :warn)
    end

    test "raises if invalid status", %{workspace: workspace} do
      check = check_fixture(fn _project -> {:invalid, "an error"} end, allow_failure: true)

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
          id: :test_check,
          module: Workspace.Checks.ValidateProject,
          opts: [
            validate: fn project -> fun.(project) end
          ]
        ],
        opts
      )

    {:ok, check} = Workspace.Check.validate(check_config)

    check
  end
end
