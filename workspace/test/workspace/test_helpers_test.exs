defmodule Workspace.TestHelpersTest do
  # with_workspace/5 purges any module loaded while it runs, so it cannot
  # run concurrently with other tests
  use ExUnit.Case, async: false

  describe "create_workspace/4" do
    @tag :tmp_dir
    test "creates the workspace and its projects", %{tmp_dir: tmp_dir} do
      Workspace.Test.create_workspace(tmp_dir, [], [{:foo, "foo", []}])

      assert File.read!(Path.join(tmp_dir, "mix.exs")) =~ "defmodule TestWorkspace.MixProject"
      assert File.read!(Path.join(tmp_dir, "foo/mix.exs")) =~ "defmodule Foo.MixProject"
    end

    @tag :tmp_dir
    test "applies the project overrides and options", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "created")

      Workspace.Test.create_workspace(path, [], [{:foo, "foo", []}],
        projects: [foo: [description: "The foo project"]]
      )

      assert File.read!(Path.join(path, "foo/mix.exs")) =~ ~s(description: "The foo project")

      path = Path.join(tmp_dir, "with")

      Workspace.Test.with_workspace(
        path,
        [],
        [{:bar, "bar", []}],
        fn ->
          assert File.read!(Path.join(path, "mix.exs")) =~ "defmodule OtherWorkspace.MixProject"
          assert File.read!(Path.join(path, "bar/mix.exs")) =~ ~s(description: "Bar")
        end,
        workspace_module: "OtherWorkspace",
        projects: [bar: [description: "Bar"]]
      )
    end

    @tag :tmp_dir
    test "raises if the path is not empty", %{tmp_dir: tmp_dir} do
      File.touch!(Path.join(tmp_dir, "file"))

      assert_raise ArgumentError, ~r/cannot create a workspace in a non empty path/, fn ->
        Workspace.Test.create_workspace(tmp_dir, [], [])
      end
    end
  end

  test "project paths must be relative" do
    assert_raise ArgumentError, "path must be relative, got: /foo", fn ->
      Workspace.Test.create_mix_project("/workspace", :foo, "/foo", [])
    end

    assert_raise ArgumentError, "path must be relative, got: /foo", fn ->
      Workspace.Test.project_fixture(:foo, "/foo", [])
    end
  end
end
