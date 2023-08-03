defmodule Workspace.UtilsTest do
  use ExUnit.Case

  alias Workspace.Utils

  describe "digraph_to_mermaid/1" do
    test "graph with edges" do
      graph = :digraph.new()

      :digraph.add_vertex(graph, :a)
      :digraph.add_vertex(graph, :b)
      :digraph.add_vertex(graph, :c)
      :digraph.add_vertex(graph, :d)

      :digraph.add_edge(graph, :a, :b)
      :digraph.add_edge(graph, :a, :c)
      :digraph.add_edge(graph, :b, :d)
      :digraph.add_edge(graph, :d, :a)
      :digraph.add_edge(graph, :d, :c)

      expected = """
      flowchart TD
        a
        b
        c
        d

        a --> b
        a --> c
        b --> d
        d --> a
        d --> c\
      """

      assert Utils.digraph_to_mermaid(graph) == expected
    end

    test "without edges" do
      graph = :digraph.new()

      :digraph.add_vertex(graph, :a)
      :digraph.add_vertex(graph, :b)
      :digraph.add_vertex(graph, :c)

      expected = """
      flowchart TD
        a
        b
        c\
      """

      assert Utils.digraph_to_mermaid(graph) == expected
    end
  end
end
