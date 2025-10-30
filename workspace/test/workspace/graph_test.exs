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

  describe "all_dependencies/2" do
    test "returns all transitive dependencies of a project" do
      workspace = Workspace.Test.workspace_fixture(:default)

      # package_d has no dependencies
      assert Graph.all_dependencies(workspace, :package_d) == []

      # package_a -> package_b -> package_g (transitive)
      # package_a -> package_c -> package_e
      # package_a -> package_c -> package_f -> package_g (transitive)
      # package_a -> package_d
      deps = Graph.all_dependencies(workspace, :package_a) |> Enum.sort()

      assert :package_b in deps
      assert :package_c in deps
      assert :package_d in deps
      assert :package_e in deps
      assert :package_f in deps
      assert :package_g in deps
    end

    test "includes nested transitive dependencies" do
      workspace = Workspace.Test.workspace_fixture(:default)

      # package_c -> package_e, package_f
      # package_f -> package_g
      deps = Graph.all_dependencies(workspace, :package_c) |> Enum.sort()

      assert deps == [:package_e, :package_f, :package_g]
    end

    test "single level dependency returns only direct dependencies" do
      workspace = Workspace.Test.workspace_fixture(:default)

      # package_b -> package_g (single level)
      deps = Graph.all_dependencies(workspace, :package_b)

      assert deps == [:package_g]
    end
  end

  describe "all_dependents/2" do
    test "returns all projects that depend on the given project transitively" do
      workspace = Workspace.Test.workspace_fixture(:default)

      # package_g is depended on by package_b and package_f
      # package_b is depended on by package_a
      # package_f is depended on by package_c
      # package_c is depended on by package_a
      # So all_dependents of package_g should include: package_a, package_b, package_c, package_f
      dependents = Graph.all_dependents(workspace, :package_g) |> Enum.sort()

      assert :package_a in dependents
      assert :package_b in dependents
      assert :package_c in dependents
      assert :package_f in dependents
    end

    test "returns empty list for projects with no dependents" do
      workspace = Workspace.Test.workspace_fixture(:default)

      # package_a is a source project with no dependents
      assert Graph.all_dependents(workspace, :package_a) == []
    end

    test "returns direct and transitive dependents" do
      workspace = Workspace.Test.workspace_fixture(:default)

      # package_d is depended on by package_a and package_h
      dependents = Graph.all_dependents(workspace, :package_d) |> Enum.sort()

      assert :package_a in dependents
      assert :package_h in dependents
    end
  end
end
