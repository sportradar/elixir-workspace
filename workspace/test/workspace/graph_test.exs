defmodule Workspace.GraphTest do
  use ExUnit.Case

  alias Workspace.Graph

  setup do
    %{workspace: Workspace.new!("test/fixtures/sample_workspace")}
  end

  describe "digraph/1" do
    test "graph of sample workspace", %{workspace: workspace} do
      graph = Graph.digraph(workspace)

      assert length(:digraph.vertices(graph)) == 11
      assert length(:digraph.edges(graph)) == 9

      :digraph.delete(graph)
    end

    test "with external dependencies set", %{workspace: workspace} do
      graph = Graph.digraph(workspace, external: true)

      assert length(:digraph.vertices(graph)) == 12
      assert {:foo, :external} in :digraph.vertices(graph)

      assert length(:digraph.edges(graph)) == 10

      :digraph.delete(graph)
    end

    test "with ignore set", %{workspace: workspace} do
      graph = Graph.digraph(workspace, ignore: ["package_a", "package_b", "package_c"])

      assert length(:digraph.vertices(graph)) == 8
      refute {:package_a, :workspace} in :digraph.vertices(graph)
      refute {:package_b, :workspace} in :digraph.vertices(graph)
      refute {:package_c, :workspace} in :digraph.vertices(graph)
      assert {:package_d, :workspace} in :digraph.vertices(graph)

      assert length(:digraph.edges(graph)) == 3

      :digraph.delete(graph)
    end
  end

  describe "with_digraph/2" do
    test "runs a function on the graph", %{workspace: workspace} do
      assert Graph.with_digraph(workspace, fn graph -> :digraph.source_vertices(graph) end)
             |> Enum.sort() == [
               {:package_a, :workspace},
               {:package_h, :workspace},
               {:package_i, :workspace},
               {:package_k, :workspace}
             ]
    end
  end

  test "source_projects/1", %{workspace: workspace} do
    assert Graph.source_projects(workspace) |> Enum.sort() == [
             :package_a,
             :package_h,
             :package_i,
             :package_k
           ]
  end

  test "sink_projects/1", %{workspace: workspace} do
    assert Graph.sink_projects(workspace) |> Enum.sort() == [
             :package_d,
             :package_e,
             :package_g,
             :package_j,
             :package_k
           ]
  end

  describe "affected/2" do
    test "nothing affected with no changes", %{workspace: workspace} do
      assert Graph.affected(workspace, []) == []
    end

    test "proper traversing up of the graph", %{workspace: workspace} do
      assert Graph.affected(workspace, [:package_k, :package_a]) |> Enum.sort() == [
               :package_a,
               :package_k
             ]

      assert Graph.affected(workspace, [:package_g]) |> Enum.sort() == [
               :package_a,
               :package_b,
               :package_c,
               :package_f,
               :package_g
             ]
    end
  end
end
