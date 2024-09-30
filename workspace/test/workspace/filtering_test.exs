defmodule Workspace.FilteringTest do
  use ExUnit.Case
  import Workspace.TestUtils

  setup do
    project_a =
      project_fixture(app: :foo, workspace: [tags: [:foo, {:scope, :ui}]], deps: [{:bar}])

    project_b = project_fixture(app: :bar, workspace: [tags: [:bar]])
    project_c = project_fixture(app: :baz, workspace: [tags: [:foo, :bar]])

    workspace = workspace_fixture([project_a, project_b, project_c])

    %{workspace: workspace}
  end

  describe "run/2" do
    test "filters and updates the given workspace", %{workspace: workspace} do
      workspace = Workspace.Filtering.run(workspace, exclude: [:bar])

      assert workspace.projects[:bar].skip
      refute workspace.projects[:foo].skip
      refute workspace.projects[:baz].skip
    end

    test "if app is excluded skips the project", %{workspace: workspace} do
      workspace = Workspace.Filtering.run(workspace, exclude: ["bar"])

      assert Workspace.project!(workspace, :bar).skip
      refute Workspace.project!(workspace, :foo).skip
      refute Workspace.project!(workspace, :baz).skip
    end

    test "if app in selected it is not skipped - everything else is skipped", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, project: ["bar"])

      refute Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :foo).skip
      assert Workspace.project!(workspace, :baz).skip
    end

    test "ignore has priority over project", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, exclude: [:bar], project: [:bar])

      assert Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :foo).skip
    end

    test "with a single excluded tag", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, excluded_tags: [:bar])

      assert Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :baz).skip
      refute Workspace.project!(workspace, :foo).skip
    end

    test "with multiple excluded tags", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, excluded_tags: [:bar, :foo])

      assert Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :baz).skip
      assert Workspace.project!(workspace, :foo).skip
    end

    test "with a single selected tag", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, tags: [:bar])

      refute Workspace.project!(workspace, :bar).skip
      refute Workspace.project!(workspace, :baz).skip
      assert Workspace.project!(workspace, :foo).skip
    end

    test "with multiple selected tags", %{
      workspace: workspace
    } do
      workspace = Workspace.Filtering.run(workspace, tags: [:bar, :foo])

      refute Workspace.project!(workspace, :bar).skip
      refute Workspace.project!(workspace, :baz).skip
      refute Workspace.project!(workspace, :foo).skip
    end

    test "with scoped tags", %{workspace: workspace} do
      workspace = Workspace.Filtering.run(workspace, tags: [{:scope, :ui}])

      assert Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :baz).skip
      refute Workspace.project!(workspace, :foo).skip
    end

    test "with binary tags", %{workspace: workspace} do
      workspace = Workspace.Filtering.run(workspace, tags: ["scope:ui", "bar"])

      refute Workspace.project!(workspace, :bar).skip
      refute Workspace.project!(workspace, :baz).skip
      refute Workspace.project!(workspace, :foo).skip
    end

    test "with invalid tags", %{workspace: workspace} do
      message = "invalid tag, it should be `tag` or `scope:tag`, got: \"scope:with:ui\""

      assert_raise ArgumentError, message, fn ->
        Workspace.Filtering.run(workspace, tags: ["scope:with:ui"])
      end

      assert_raise ArgumentError, fn ->
        Workspace.Filtering.run(workspace, tags: [1])
      end
    end

    test "with dependency set", %{workspace: workspace} do
      workspace = Workspace.Filtering.run(workspace, dependency: :invalid)

      assert Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :baz).skip
      assert Workspace.project!(workspace, :foo).skip

      workspace = Workspace.Filtering.run(workspace, dependency: :bar)

      assert Workspace.project!(workspace, :bar).skip
      assert Workspace.project!(workspace, :baz).skip
      refute Workspace.project!(workspace, :foo).skip
    end
  end
end
