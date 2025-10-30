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
      filtered = Workspace.Filtering.run(workspace, exclude: [:bar])

      assert filtered.projects[:bar].skip
      refute filtered.projects[:foo].skip
      refute filtered.projects[:baz].skip
    end

    test "if app is excluded skips the project", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, exclude: ["bar"])

      assert Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :baz).skip
    end

    test "if app in selected it is not skipped - everything else is skipped", %{
      workspace: workspace
    } do
      filtered = Workspace.Filtering.run(workspace, project: ["bar"])

      refute Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :foo).skip
      assert Workspace.project!(filtered, :baz).skip
    end

    test "ignore has priority over project", %{
      workspace: workspace
    } do
      filtered = Workspace.Filtering.run(workspace, exclude: [:bar], project: [:bar])

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :foo).skip
    end

    test "with a single excluded tag", %{
      workspace: workspace
    } do
      filtered = Workspace.Filtering.run(workspace, excluded_tags: [:bar])

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      refute Workspace.project!(filtered, :foo).skip
    end

    test "with multiple excluded tags", %{
      workspace: workspace
    } do
      filtered = Workspace.Filtering.run(workspace, excluded_tags: [:bar, :foo])

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      assert Workspace.project!(filtered, :foo).skip
    end

    test "with a single selected tag", %{
      workspace: workspace
    } do
      filtered = Workspace.Filtering.run(workspace, tags: [:bar])

      refute Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
      assert Workspace.project!(filtered, :foo).skip
    end

    test "with multiple selected tags", %{
      workspace: workspace
    } do
      filtered = Workspace.Filtering.run(workspace, tags: [:bar, :foo])

      refute Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
      refute Workspace.project!(filtered, :foo).skip
    end

    test "with scoped tags", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, tags: [{:scope, :ui}])

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      refute Workspace.project!(filtered, :foo).skip
    end

    test "with binary tags", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, tags: ["scope:ui", "bar"])

      refute Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
      refute Workspace.project!(filtered, :foo).skip
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

    test "with paths set", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, paths: ["packages"])

      refute Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
      refute Workspace.project!(filtered, :foo).skip

      filtered = Workspace.Filtering.run(workspace, paths: ["packages/foo", "packages/baz"])

      assert Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
      refute Workspace.project!(filtered, :foo).skip

      filtered = Workspace.Filtering.run(workspace, paths: ["packages/food", "packages/baze"])

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      assert Workspace.project!(filtered, :foo).skip
    end

    test "with dependency set", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, dependency: :invalid)

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      assert Workspace.project!(filtered, :foo).skip

      filtered = Workspace.Filtering.run(workspace, dependency: :bar)

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      refute Workspace.project!(filtered, :foo).skip
    end

    test "with dependent set", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, dependent: :bar)

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      assert Workspace.project!(filtered, :foo).skip

      filtered = Workspace.Filtering.run(workspace, dependent: :foo)

      refute Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
      assert Workspace.project!(filtered, :foo).skip
    end

    test "with include adds back filtered projects", %{workspace: workspace} do
      # Filter to only foo project, but include bar back
      filtered = Workspace.Filtering.run(workspace, project: [:foo], include: [:bar])

      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
    end

    test "include with string values", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, project: ["foo"], include: ["bar"])

      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
    end

    test "include with multiple projects", %{workspace: workspace} do
      # Filter to only foo, but include bar and baz back
      filtered = Workspace.Filtering.run(workspace, project: [:foo], include: [:bar, :baz])

      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
    end

    test "include works with tags filter", %{workspace: workspace} do
      # Filter to projects with :bar tag (bar and baz), but include foo back
      filtered = Workspace.Filtering.run(workspace, tags: [:bar], include: [:foo])

      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
    end

    test "exclude has priority over include", %{workspace: workspace} do
      # Exclude bar, but try to include it - exclude wins
      filtered = Workspace.Filtering.run(workspace, exclude: [:bar], include: [:bar])

      assert Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :baz).skip
    end

    test "exclude has priority over include even with project filter", %{workspace: workspace} do
      # Filter to only bar, include bar, but also exclude bar - exclude wins
      filtered =
        Workspace.Filtering.run(workspace, project: [:bar], exclude: [:bar], include: [:bar])

      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :foo).skip
      assert Workspace.project!(filtered, :baz).skip
    end

    test "include can add back projects filtered by excluded_tags", %{workspace: workspace} do
      # Exclude projects with :bar tag (bar and baz), but include baz back
      filtered = Workspace.Filtering.run(workspace, excluded_tags: [:bar], include: [:baz])

      refute Workspace.project!(filtered, :foo).skip
      assert Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
    end

    test "include with paths filter", %{workspace: workspace} do
      # Filter to projects under packages/foo only, but include bar back
      filtered = Workspace.Filtering.run(workspace, paths: ["packages/foo"], include: [:bar])

      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
    end

    test "include with dependency filter", %{workspace: workspace} do
      # Filter to projects with :bar dependency (only foo has it), but include baz back
      filtered = Workspace.Filtering.run(workspace, dependency: :bar, include: [:baz])

      refute Workspace.project!(filtered, :foo).skip
      assert Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
    end

    test "include works when no other filters are set", %{workspace: workspace} do
      # Include without any other filter should not change anything
      filtered = Workspace.Filtering.run(workspace, include: [:foo])

      refute Workspace.project!(filtered, :foo).skip
      refute Workspace.project!(filtered, :bar).skip
      refute Workspace.project!(filtered, :baz).skip
    end

    test "include with empty list does nothing", %{workspace: workspace} do
      filtered = Workspace.Filtering.run(workspace, project: [:foo], include: [])

      refute Workspace.project!(filtered, :foo).skip
      assert Workspace.project!(filtered, :bar).skip
      assert Workspace.project!(filtered, :baz).skip
    end
  end
end
