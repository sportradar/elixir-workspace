defmodule Workspace.ConfigTest do
  use ExUnit.Case

  alias Workspace.Config

  describe "validate!/1" do
    test "returns config with a valid input" do
      assert config = Config.validate!([])
      assert config[:ignore_paths] == []
    end

    test "raises in case of invalid config" do
      assert_raise ArgumentError, ~r/invalid value for :checks/, fn ->
        Config.validate!(checks: :foo)
      end
    end
  end

  describe "validate/1" do
    test "an empty config is valid" do
      assert {:ok, _config} = Config.validate([])
    end

    test "fails if the input is not a keyword list" do
      assert {:error, message} = Config.validate(:foo)
      assert message =~ "expected workspace config to be a keyword list"
    end

    test "fails with invalid config values" do
      assert {:error, message} = Config.validate(checks: :ok)
      assert message =~ "invalid value for :checks"
    end

    test "fails with invalid checks config" do
      assert {:error, message} = Config.validate(checks: [[]])
      assert message =~ "required :module option not found"
    end

    test "fails with invalid check options" do
      config = [
        checks: [
          [
            id: :test_check,
            module: Workspace.Checks.ValidateProject,
            description: "a dummy test",
            opts: [
              valid: fn _project -> {:ok, ""} end
            ]
          ]
        ]
      ]

      assert {:error, message} = Config.validate(config)
      assert message =~ "failed to validate checks"
    end

    test "other options are ignored" do
      config = [
        ignore_projects: [:foo],
        ignore_paths: ["foo", "bar"],
        checks: [],
        test_coverage: [
          threshold: 30,
          allow_failure: [:foo]
        ],
        my_option: 1,
        another_option: [x: 2]
      ]

      assert {:ok, validated_config} = Config.validate(config)
      assert Keyword.equal?(validated_config, config)
    end
  end
end
