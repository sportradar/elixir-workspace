defmodule Workspace.GraphTest do
  use ExUnit.Case, async: true

  alias Workspace.Graph

  describe "digraph/1" do
    test "graph of sample workspace" do
      workspace = Workspace.Test.workspace_fixture(:default)
      graph = Graph.digraph(workspace)

      assert length(:digraph.vertices(graph)) == 11
      assert length(:digraph.edges(graph)) == 9

      :digraph.delete(graph)
    end

    test "with external dependencies set" do
      workspace = Workspace.Test.workspace_fixture(:default)
      graph = Graph.digraph(workspace, external: true)

      nodes = Enum.map(:digraph.vertices(graph), fn node -> {node.app, node.type} end)

      assert length(:digraph.vertices(graph)) == 13
      assert {:foo, :external} in nodes

      assert length(:digraph.edges(graph)) == 11

      :digraph.delete(graph)
    end

    test "with exclude set" do
      workspace = Workspace.Test.workspace_fixture(:default)
      graph = Graph.digraph(workspace, exclude: [:package_a, "package_b", "package_c"])

      assert length(:digraph.vertices(graph)) == 8

      nodes = :digraph.vertices(graph) |> Enum.map(fn node -> {node.app, node.type} end)

      refute {:package_a, :workspace} in nodes
      refute {:package_b, :workspace} in nodes
      refute {:package_c, :workspace} in nodes
      assert {:package_d, :workspace} in nodes

      assert length(:digraph.edges(graph)) == 3

      :digraph.delete(graph)
    end
  end

  describe "with_digraph/2" do
    test "runs a function on the graph" do
      workspace = Workspace.Test.workspace_fixture(:default)
      nodes = Graph.with_digraph(workspace, fn graph -> :digraph.source_vertices(graph) end)

      for node <- nodes do
        assert %Workspace.Graph.Node{} = node
      end

      apps = Enum.map(nodes, fn node -> {node.app, node.type} end)

      assert Enum.sort(apps) == [
               {:package_a, :workspace},
               {:package_h, :workspace},
               {:package_i, :workspace},
               {:package_k, :workspace}
             ]
    end
  end

  test "source_projects/1" do
    workspace = Workspace.Test.workspace_fixture(:default)

    assert Graph.source_projects(workspace) |> Enum.sort() == [
             :package_a,
             :package_h,
             :package_i,
             :package_k
           ]

    assert Graph.source_projects(workspace) == Graph.source_projects(workspace.graph)
  end

  test "sink_projects/1" do
    workspace = Workspace.Test.workspace_fixture(:default)

    assert Graph.sink_projects(workspace) |> Enum.sort() == [
             :package_d,
             :package_e,
             :package_g,
             :package_j,
             :package_k
           ]

    assert Graph.sink_projects(workspace) == Graph.sink_projects(workspace.graph)
  end

  describe "affected/2" do
    test "nothing affected with no changes" do
      workspace = Workspace.Test.workspace_fixture(:default)
      assert Graph.affected(workspace, []) == []
    end

    test "proper traversing up of the graph" do
      workspace = Workspace.Test.workspace_fixture(:default)

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

  describe "dependencies/2" do
    test "returns the neighbours of a given node" do
      workspace = Workspace.Test.workspace_fixture(:default)
      assert Graph.dependencies(workspace, :package_d) == []

      assert Graph.dependencies(workspace, :package_a) |> Enum.sort() == [
               :package_b,
               :package_c,
               :package_d
             ]
    end
  end
end
