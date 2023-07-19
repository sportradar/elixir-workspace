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
  end
end
